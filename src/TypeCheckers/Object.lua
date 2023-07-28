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

type ObjectTypeChecker = TypeChecker<ObjectTypeChecker, {[any]: any}> & {
    ContainsValueOfType: SelfReturn<ObjectTypeChecker, SignatureTypeChecker>;
    ContainsKeyOfType: SelfReturn<ObjectTypeChecker, SignatureTypeChecker>;
    CheckMetatable: SelfReturn<ObjectTypeChecker, SignatureTypeChecker>;
    OfValueType: SelfReturn<ObjectTypeChecker, SignatureTypeChecker>;
    OfStructure: SelfReturn<ObjectTypeChecker, {[any]: SignatureTypeChecker}>;
    OfKeyType: SelfReturn<ObjectTypeChecker, SignatureTypeChecker>;
    IsFrozen: SelfReturn<ObjectTypeChecker>;
    MinSize: SelfReturn<ObjectTypeChecker, number | (any?) -> number>;
    MaxSize: SelfReturn<ObjectTypeChecker, number | (any?) -> number>;
    OfClass: SelfReturn<ObjectTypeChecker, any>;
    Strict: SelfReturn<ObjectTypeChecker>;
};

local Object: TypeCheckerConstructor<ObjectTypeChecker, {[any]: SignatureTypeChecker}?>, ObjectClass = Template.Create("Object")

function ObjectClass._Initial(TargetObject)
    if (type(TargetObject) == "table") then
        -- This is fully reliable but uncomfortably slow, and therefore disabled for the meanwhile.
        --[[
            for Key in TargetObject do
                if (typeof(Key) == "number") then
                    return false, "Incorrect key type: number"
                end
            end
        ]]

        -- This will catch the majority of cases.
        if (rawget(TargetObject, 1) == nil) then
            return true
        end

        return false, "Incorrect key type: numeric index [1]"
    end

    return false, `Expected table, got {type(TargetObject)}`
end

--- Ensures every key that exists in the subject also exists in the structure passed, optionally strict i.e. no extra key-value pairs.
function ObjectClass:OfStructure(OriginalSubTypes)
    ExpectType(OriginalSubTypes, Expect.TABLE, 1)

    -- Just in case the user does any weird mutation.
    local SubTypesCopy = {}

    for Index, Value in OriginalSubTypes do
        AssertIsTypeBase(Value, Index)
        SubTypesCopy[Index] = Value
    end

    setmetatable(SubTypesCopy, StructureStringMT)

    return self:_AddConstraint(true, "OfStructure", function(SelfRef, StructureCopy, SubTypes)
        -- Check all fields which should be in the object exist and the type check for each passes.
        for Key, Checker in SubTypes do
            local Success, SubMessage = Checker:_Check(StructureCopy[Key])

            if (not Success) then
                return false, `[Key '{Key}'] {SubMessage}`
            end
        end

        -- Check there are no extra fields which shouldn't be in the object.
        if (SelfRef._Tags.Strict) then
            for Key in StructureCopy do
                if (not SubTypes[Key]) then
                    return false, `[Key '{Key}'] unexpected (strict)`
                end
            end
        end

        return true
    end, SubTypesCopy)
end

--- For all values in the passed table, they must satisfy the TypeChecker passed to this constraint.
function ObjectClass:OfValueType(SubType)
    AssertIsTypeBase(SubType, 1)

    return self:_AddConstraint(true, "OfValueType", function(_, TargetArray, SubType)
        for Index, Value in TargetArray do
            local Success, SubMessage = SubType:_Check(Value)

            if (not Success) then
                return false, `[OfValueType: Key '{Index}'] {SubMessage}`
            end
        end

        return true
    end, SubType)
end

--- For all keys in the passed table, they must satisfy the TypeChecker passed to this constraint.
function ObjectClass:OfKeyType(SubType)
    AssertIsTypeBase(SubType, 1)

    return self:_AddConstraint(true, "OfKeyType", function(_, TargetArray, SubType)
        for Key in TargetArray do
            local Success, SubMessage = SubType:_Check(Key)

            if (not Success) then
                return false, `[OfKeyType: Key '{Key}'] {SubMessage}`
            end
        end

        return true
    end, SubType)
end

--- Strict i.e. no extra key-value pairs than what is explicitly specified when using OfStructure.
function ObjectClass:Strict()
    return self:_AddTag("Strict")
end

--- Checks if an object is frozen.
function ObjectClass:IsFrozen()
    return self:_AddConstraint(true, "IsFrozen", function(_, TargetObject)
        if (table.isfrozen(TargetObject)) then
            return true
        end

        return false, "Table was not frozen"
    end)
end

--- Checks an object's metatable.
function ObjectClass:CheckMetatable(Checker)
    AssertIsTypeBase(Checker, 1)

    return self:_AddConstraint(true, "CheckMetatable", function(_, TargetObject, Checker)
        local Success, Message = Checker:_Check(getmetatable(TargetObject))

        if (Success) then
            return true
        end

        return false, `[Metatable] {Message}`
    end, Checker)
end

--- Checks if an object's __index points to the specified class.
function ObjectClass:OfClass(Class)
    ExpectType(Class, Expect.TABLE, 1)
    assert(Class.__index, "Class must have an __index")

    return self:CheckMetatable(Object():Equals(Class))
end

--- Checks if an object contains a value which satisfies the given TypeChecker.
function ObjectClass:ContainsValueOfType(Checker)
    AssertIsTypeBase(Checker, 1)

    return self:_AddConstraint(false, "ContainsValueOfType", function(_, TargetObject, Checker)
        for _, Value in TargetObject do
            local Success = Checker:_Check(Value)

            if (Success) then
                return true
            end
        end

        return false, `[ContainsValueOfType] did not contain any values which satisfied {Checker}`
    end, Checker)
end

--- Checks if an object contains a value which satisfies the given TypeChecker.
function ObjectClass:ContainsKeyOfType(Checker)
    AssertIsTypeBase(Checker, 1)

    return self:_AddConstraint(false, "ContainsKeyOfType", function(_, TargetObject, Checker)
        for Key in TargetObject do
            local Success = Checker:_Check(Key)

            if (Success) then
                return true
            end
        end

        return false, `[ContainsKeyOfType] did not contain any values which satisfied {Checker}`
    end, Checker)
end

function ObjectClass:MinSize(MinSize)
    ExpectType(MinSize, Expect.NUMBER_OR_FUNCTION, 1)

    return self:_AddConstraint(true, "MinSize", function(_, TargetObject, MinSize)
        local Count = 0

        for _ in TargetObject do
            Count += 1
        end

        if (Count < MinSize) then
            return false, `[MinSize] expected at least {MinSize} elements, got {Count}`
        end

        return true
    end, MinSize)
end

function ObjectClass:MaxSize(MaxSize)
    ExpectType(MaxSize, Expect.NUMBER_OR_FUNCTION, 1)

    return self:_AddConstraint(true, "MaxSize", function(_, TargetObject, MaxSize)
        local Count = 0

        for _ in TargetObject do
            Count += 1
        end

        if (Count > MaxSize) then
            return false, `[MaxSize] expected at most {MaxSize} elements, got {Count}`
        end

        return true
    end, MaxSize)
end

ObjectClass.InitialConstraint = ObjectClass.OfStructure

return Object