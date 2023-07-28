local Template = require(script.Parent:WaitForChild("_Template"))
    type TypeCheckerConstructor<T, P...> = Template.TypeCheckerConstructor<T, P...>
    type SignatureTypeChecker = Template.SignatureTypeChecker
    type TypeChecker<ExtensionClass, Primitive> = Template.TypeChecker<ExtensionClass, Primitive>
    type SelfReturn<T, P...> = Template.SelfReturn<T, P...>

local Util = require(script.Parent.Parent:WaitForChild("Util"))
    local StructureStringMT = Util.StructureStringMT
    local AssertIsTypeBase = Util.AssertIsTypeBase
    local ExpectType = Util.ExpectType
    local Expect = Util.Expect

type ArrayTypeChecker = TypeChecker<ArrayTypeChecker, {any}> & {
    ContainsValueOfType: SelfReturn<ArrayTypeChecker, SignatureTypeChecker, number?>;
    OfStructureStrict: SelfReturn<ArrayTypeChecker, {SignatureTypeChecker}>;
    OfStructure: SelfReturn<ArrayTypeChecker, {SignatureTypeChecker}>;
    MinLength: SelfReturn<ArrayTypeChecker, number | (any?) -> number>;
    MaxLength: SelfReturn<ArrayTypeChecker, number | (any?) -> number>;
    IsOrdered: SelfReturn<ArrayTypeChecker, boolean | (any?) -> boolean>;
    IsFrozen: SelfReturn<ArrayTypeChecker>;
    OfLength: SelfReturn<ArrayTypeChecker, number | (any?) -> number>;
    Contains: SelfReturn<ArrayTypeChecker, any>;
    OfType: SelfReturn<ArrayTypeChecker, SignatureTypeChecker>;
    Strict: SelfReturn<ArrayTypeChecker>;
};

local Array: TypeCheckerConstructor<ArrayTypeChecker, SignatureTypeChecker?>, ArrayClass = Template.Create("Array")

function ArrayClass._Initial(TargetArray)
    if (type(TargetArray) == "table") then
        -- This is fully reliable but uncomfortably slow, and therefore disabled for the meanwhile.
        --[[
            for Key in TargetArray do
                local KeyType = typeof(Key)

                if (KeyType ~= "number") then
                    return false, "Non-numeric key detected: " .. KeyType
                end
            end
        ]]

        -- This will catch the majority of cases.
        local FirstKey = next(TargetArray)

        if (FirstKey == nil or FirstKey == 1) then
            return true
        end

        return false, "Array is empty"
    end

    return false, `Expected table, got {type(TargetArray)}`
end

--- Ensures an array is of a certain length.
function ArrayClass:OfLength(Length)
    ExpectType(Length, Expect.NUMBER_OR_FUNCTION, 1)

    return self:_AddConstraint(true, "Length", function(_, TargetArray, Length)
        if (#TargetArray ~= Length) then
            return false, `Length must be {Length}, got {#TargetArray}`
        end

        return true
    end, Length)
end

--- Ensures an array is at least a certain length.
function ArrayClass:MinLength(MinLength)
    ExpectType(MinLength, Expect.NUMBER_OR_FUNCTION, 1)

    return self:_AddConstraint(true, "MinLength", function(_, TargetArray, MinLength)
        if (#TargetArray < MinLength) then
            return false, `Length must be at least {MinLength}, got {#TargetArray}`
        end

        return true
    end, MinLength)
end

--- Ensures an array is at most a certain length.
function ArrayClass:MaxLength(MaxLength)
    ExpectType(MaxLength, Expect.NUMBER_OR_FUNCTION, 1)

    return self:_AddConstraint(true, "MaxLength", function(_, TargetArray, MaxLength)
        if (#TargetArray > MaxLength) then
            return false, `Length must be at most {MaxLength}, got {#TargetArray}`
        end

        return true
    end, MaxLength)
end

--- Ensures an array contains some given value.
function ArrayClass:Contains(Value, StartPoint)
    if (Value == nil) then
        ExpectType(Value, Expect.SOMETHING, 1)
    end

    if (StartPoint) then
        ExpectType(StartPoint, Expect.NUMBER_OR_FUNCTION, 2)
    end

    return self:_AddConstraint(false, "Contains", function(_, TargetArray, Value, StartPoint)
        if (table.find(TargetArray, Value, StartPoint) == nil) then
            return false, `Value not found in array: {Value}`
        end

        return true
    end, Value, StartPoint)
end

--- Ensures an array contains a value satisfying the provided TypeChecker.
function ArrayClass:ContainsValueOfType(Checker, StartPoint)
    AssertIsTypeBase(Checker, 1)

    if (StartPoint ~= nil) then
        ExpectType(StartPoint, Expect.NUMBER_OR_FUNCTION, 2)
    end

    return self:_AddConstraint(false, "ContainsValueOfType", function(_, TargetArray, Checker, StartPoint)
        if (StartPoint) then
            for Index = StartPoint, #TargetArray do
                local Value = TargetArray[Index]

                if (Checker:_Check(Value)) then
                    return true
                end
            end
        else
            for Index, Value in TargetArray do
                if (Checker:_Check(Value)) then
                    return true
                end
            end
        end

        return false, `No value in array satisfied the checker`
    end, Checker, StartPoint)
end

--- Ensures each value in the template array satisfies the passed TypeChecker.
function ArrayClass:OfType(SubType)
    AssertIsTypeBase(SubType, 1)

    return self:_AddConstraint(true, "OfType", function(SelfRef, TargetArray, SubType)
        for Index, Value in TargetArray do
            local Success, SubMessage = SubType:_Check(Value)

            if (not Success) then
                return false, `[Index #{Index}] {SubMessage}`
            end
        end

        return true
    end, SubType)
end

-- Takes an array of types and checks it against the passed array.
function ArrayClass:OfStructure(SubTypesAtPositions)
    ExpectType(SubTypesAtPositions, Expect.TABLE, 1)

    -- Just in case the user does any weird mutation.
    local SubTypesCopy = table.create(#SubTypesAtPositions)

    for Index, Value in SubTypesAtPositions do
        AssertIsTypeBase(Value, Index)
        SubTypesCopy[Index] = Value
    end

    setmetatable(SubTypesCopy, StructureStringMT)

    return self:_AddConstraint(true, "OfStructure", function(SelfRef, TargetArray, SubTypesAtPositions)
        -- Check all fields which should be in the object exist and the type check for each passes.
        for Index, Checker in SubTypesAtPositions do
            local Success, SubMessage = Checker:_Check(TargetArray[Index])

            if (not Success) then
                return false, `[Index #{Index}] {SubMessage}`
            end
        end

        -- Check there are no extra indexes which shouldn't be in the object.
        if (SelfRef._Tags.Strict) then
            for Index in TargetArray do
                local Checker = SubTypesAtPositions[Index]

                if (not Checker) then
                    return false, `[Index #{Index}] Unexpected value (strict tag is present)`
                end
            end
        end

        return true
    end, SubTypesCopy, SubTypesAtPositions)
end

--- OfStructure but strict.
function ArrayClass:OfStructureStrict(Other)
    return self:OfStructure(Other):Strict()
end

--- Tags this ArrayTypeChecker as strict i.e. no extra indexes allowed in OfStructure constraint.
function ArrayClass:Strict()
    return self:_AddTag("Strict")
end

--- Checks if an array is frozen.
function ArrayClass:IsFrozen()
    return self:_AddConstraint(true, "IsFrozen", function(_, TargetArray)
        if (table.isfrozen(TargetArray)) then
            return true
        end

        return false, "Table was not frozen"
    end)
end

--- Checks if an array is ordered.
function ArrayClass:IsOrdered(Descending)
    if (Descending ~= nil) then
        ExpectType(Descending, Expect.BOOLEAN_OR_FUNCTION, 1)
    end

    return self:_AddConstraint(true, "IsOrdered", function(_, TargetArray, Descending)
        local Ascending = not Descending
        local Size = #TargetArray

        if (Size == 1) then
            return true
        end

        local Last = TargetArray[1]

        for Index = 2, Size do
            local Current = TargetArray[Index]

            if (Descending and Last < Current) then
                return false, `Array is not ordered descending at index {Index}`
            elseif (Ascending and Last > Current) then
                return false, `Array is not ordered ascending at index {Index}`
            end

            Last = Current
        end

        return true
    end, Descending)
end

ArrayClass.InitialConstraint = ArrayClass.OfType

return Array