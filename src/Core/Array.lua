--!native
--!optimize 2

if (not script and Instance) then
    script = game:GetService("ReplicatedFirst").TypeGuard.Core.Array
end

local Template = require(script.Parent.Parent._Template)
    type TypeCheckerConstructor<T, P...> = Template.TypeCheckerConstructor<T, P...>
    type SignatureTypeChecker = Template.SignatureTypeChecker
    type FunctionalArg<T> = Template.FunctionalArg<T>
    type TypeChecker<ExtensionClass, Primitive> = Template.TypeChecker<ExtensionClass, Primitive>

local Util = require(script.Parent.Parent.Util)
    local StructureStringMT = Util.StructureStringMT
    local AssertIsTypeBase = Util.AssertIsTypeBase
    local ExpectType = Util.ExpectType
    local Expect = Util.Expect

local TableUtil = require(script.Parent.Parent.Parent.TableUtil).WithFeatures()
    local Merge = TableUtil.Map.Merge

local Number = require(script.Parent.Number)

type ArrayTypeChecker = TypeChecker<ArrayTypeChecker, {any}> & {
    ContainsValueOfType: ((self: ArrayTypeChecker, Type: FunctionalArg<SignatureTypeChecker>, StartPoint: FunctionalArg<number?>) -> (ArrayTypeChecker));
    OfStructure: ((self: ArrayTypeChecker, Structure: FunctionalArg<{SignatureTypeChecker}>) -> (ArrayTypeChecker));
    MinLength: ((self: ArrayTypeChecker, MinLength: FunctionalArg<number>) -> (ArrayTypeChecker));
    MaxLength: ((self: ArrayTypeChecker, MaxLength: FunctionalArg<number>) -> (ArrayTypeChecker));
    IsOrdered: ((self: ArrayTypeChecker, AscendingOrDescendingOrEither: FunctionalArg<boolean>) -> (ArrayTypeChecker));
    IsFrozen: ((self: ArrayTypeChecker) -> (ArrayTypeChecker));
    OfLength: ((self: ArrayTypeChecker, Length: FunctionalArg<number>) -> (ArrayTypeChecker));
    Contains: ((self: ArrayTypeChecker, Value: FunctionalArg<any>) -> (ArrayTypeChecker));
    OfType: ((self: ArrayTypeChecker, Type: FunctionalArg<SignatureTypeChecker>) -> (ArrayTypeChecker));
    Strict: ((self: ArrayTypeChecker) -> (ArrayTypeChecker));

    Similarity: ((self: ArrayTypeChecker, Value: any) -> (number));
};

local Array: ((Type: FunctionalArg<SignatureTypeChecker?>) -> (ArrayTypeChecker)), ArrayClass = Template.Create("Array")
ArrayClass._TypeOf = {"table"}

function ArrayClass:_Initial(TargetArray)
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
    return self:MinLength(Length):MaxLength(Length)
end

local function _MinLength(_, TargetArray, MinLength)
    if (#TargetArray < MinLength) then
        return false, `Length must be at least {MinLength}, got {#TargetArray}`
    end

    return true
end

--- Ensures an array is at least a certain length.
function ArrayClass:MinLength(MinLength)
    ExpectType(MinLength, Expect.NUMBER_OR_FUNCTION, 1)

    return self:_AddConstraint(true, "MinLength", _MinLength, MinLength)
end

local function _MaxLength(_, TargetArray, MaxLength)
    if (#TargetArray > MaxLength) then
        return false, `Length must be at most {MaxLength}, got {#TargetArray}`
    end

    return true
end

--- Ensures an array is at most a certain length.
function ArrayClass:MaxLength(MaxLength)
    ExpectType(MaxLength, Expect.NUMBER_OR_FUNCTION, 1)

    return self:_AddConstraint(true, "MaxLength", _MaxLength, MaxLength)
end

local function _Contains(_, TargetArray, Value, StartPoint)
    if (table.find(TargetArray, Value, StartPoint) == nil) then
        return false, `Value not found in array: {Value}`
    end

    return true
end

--- Ensures an array contains some given value.
function ArrayClass:Contains(Value, StartPoint)
    if (Value == nil) then
        ExpectType(Value, Expect.SOMETHING, 1)
    end

    if (StartPoint) then
        ExpectType(StartPoint, Expect.NUMBER_OR_FUNCTION, 2)
    end

    return self:_AddConstraint(false, "Contains", _Contains, Value, StartPoint)
end

local function _ContainsValueOfType(_, TargetArray, Checker, StartPoint)
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
end

--- Ensures an array contains a value satisfying the provided TypeChecker.
function ArrayClass:ContainsValueOfType(Checker, StartPoint)
    AssertIsTypeBase(Checker, 1)

    if (StartPoint ~= nil) then
        ExpectType(StartPoint, Expect.NUMBER_OR_FUNCTION, 2)
    end

    return self:_AddConstraint(false, "ContainsValueOfType", _ContainsValueOfType, Checker, StartPoint)
end

local function _OfType(SelfRef, TargetArray, SubType)
    for Index, Value in TargetArray do
        local Success, SubMessage = SubType:_Check(Value)

        if (not Success) then
            return false, `[Index #{Index}] {SubMessage}`
        end
    end

    return true
end

--- Ensures each value in the template array satisfies the passed TypeChecker.
function ArrayClass:OfType(SubType)
    if (type(SubType) ~= "function") then
        AssertIsTypeBase(SubType, 1)
    end

    return self:_AddConstraint(true, "OfType", _OfType, SubType)
end

local function _OfStructure(SelfRef, TargetArray, SubTypesAtPositions)
    -- Check all fields which should be in the object exist and the type check for each passes.
    for Index, Checker in SubTypesAtPositions do
        local Success, SubMessage = Checker:_Check(TargetArray[Index])

        if (not Success) then
            return false, `[Index #{Index}] {SubMessage}`
        end
    end

    -- Check there are no extra indexes which shouldn't be in the object.
    if (SelfRef._Strict) then
        for Index in TargetArray do
            local Checker = SubTypesAtPositions[Index]

            if (not Checker) then
                return false, `[Index #{Index}] Unexpected value (strict tag is present)`
            end
        end
    end

    return true
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

    return self:_AddConstraint(true, "OfStructure", _OfStructure, SubTypesCopy, SubTypesAtPositions)
end

--- Tags this ArrayTypeChecker as strict i.e. no extra indexes allowed in OfStructure constraint.
function ArrayClass:Strict()
    return self:Modify({
        _Strict = true;
    })
end

local function _IsFrozen(_, TargetArray)
    if (table.isfrozen(TargetArray)) then
        return true
    end

    return false, "Table was not frozen"
end

--- Checks if an array is frozen.
function ArrayClass:IsFrozen()
    return self:_AddConstraint(true, "IsFrozen", _IsFrozen)
end

local function _IsOrdered(_, TargetArray, Descending)
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
end

--- Checks if an array is ordered.
function ArrayClass:IsOrdered(Descending)
    if (Descending ~= nil) then
        ExpectType(Descending, Expect.BOOLEAN_OR_FUNCTION, 1)
    end

    return self:_AddConstraint(true, "IsOrdered", _IsOrdered, Descending)
end

function ArrayClass:Similarity(Value)
    local Similarity = 0

    if (self:_Initial(Value)) then
        Similarity += 1
    else
        return Similarity
    end

    local OfStructure = self:GetConstraint("OfStructure")

    if (OfStructure) then
        for Key, Checker in OfStructure[1] do
            local GotValue = Value[Key]

            -- Presence of key -> +1.
            if (GotValue ~= nil) then
                Similarity += 1
            end

            -- Presence of correct checked value -> +1.
            local SubSimilarity = Checker.Similarity
            Value += SubSimilarity and SubSimilarity(Checker, GotValue) or 0
        end
    end

    local OfType = self:GetConstraint("OfType")

    if (OfType) then
        local ValueType = OfType[1]
        local ValueSimilarity = ValueType.Similarity

        for _, Value in Value do
            Similarity += ValueSimilarity and ValueSimilarity(ValueType, Value) or 1
        end
    end

    return Similarity
end

ArrayClass.InitialConstraint = ArrayClass.OfType

local DynamicUInt = Number():Integer(32, false):Positive():Dynamic()
    local DynamicUIntDeserialize = DynamicUInt._Deserialize
    local DynamicUIntSerialize = DynamicUInt._Serialize

function ArrayClass:_UpdateSerialize()
    local HasFunctionalConstraints = self:_HasFunctionalConstraints()
    local IsFrozen = self:GetConstraint("IsFrozen")
    local Type = self:GetConstraint("OfType")
    local Any

    if (HasFunctionalConstraints or not Type) then
        return {
            _Serialize = function(Buffer, Value, Context)
                local BufferContext = Buffer.Context

                if (BufferContext) then
                    BufferContext("Array(Any)")
                end

                local Serialize = (Context and Context.AnySerialize or nil)

                if (Serialize == nil) then
                    Any = Any or require(script.Parent.ValueCache)((require(script.Parent.Parent.Roblox.Any) :: any)())
                        Serialize = Any._Serialize

                    Context = Merge(Context or {}, {
                        AnySerialize = Serialize;
                    })
                end

                Serialize(Buffer, Value, Context)

                if (BufferContext) then
                    BufferContext()
                end
            end;
            _Deserialize = function(Buffer, Context)
                local Deserialize = (Context and Context.AnyDeserialize or nil)

                if (Deserialize == nil) then
                    Any = Any or require(script.Parent.ValueCache)((require(script.Parent.Parent.Roblox.Any) :: any)())
                        Deserialize = Any._Deserialize

                    Context = Merge(Context or {}, {
                        AnyDeserialize = Deserialize;
                    })
                end

                return Deserialize(Buffer, Context)
            end;
        }
    end

    local Checker = Type[1]
        local Serializer = Checker._Serialize
        local Deserializer = Checker._Deserialize

    local MinLength = self:GetConstraint("MinLength")
    local MaxLength = self:GetConstraint("MaxLength")

    if (MinLength and MaxLength) then
        local MinLengthValue = MinLength[1]
        local MaxLengthValue = MaxLength[1]

        if (MinLengthValue == MaxLengthValue) then
            return {
                _Serialize = function(Buffer, Array, Context)
                    local BufferContext = Buffer.Context

                    if (BufferContext) then
                        BufferContext("Array(OfType, FixedLength)")
                    end

                    for _, Value in Array do
                        Serializer(Buffer, Value, Context)
                    end

                    if (BufferContext) then
                        BufferContext()
                    end
                end;

                _Deserialize = function(Buffer, Context)
                    local Array = table.create(MaxLengthValue)
                    local CaptureInto = (Context and Context.CaptureInto or nil)

                    if (CaptureInto) then
                        CaptureInto[Context.CaptureValue] = Array
                        Context.CaptureInto = nil
                    end

                    for Index = 1, MaxLengthValue do
                        Array[Index] = Deserializer(Buffer, Context)
                    end

                    if (IsFrozen) then
                        table.freeze(Array)
                    end

                    return Array
                end;
            }
        end

        local NumberSerializer = Number(MinLengthValue, MaxLengthValue):Integer()
            local NumberDeserialize = NumberSerializer._Deserialize
            local NumberSerialize = NumberSerializer._Serialize

        return {
            _Serialize = function(Buffer, Array, Context)
                local BufferContext = Buffer.Context

                if (BufferContext) then
                    BufferContext("Array(OfType, MinLength, MaxLength)")
                end

                NumberSerialize(Buffer, #Array, Context)

                for _, Value in Array do
                    Serializer(Buffer, Value, Context)
                end

                if (BufferContext) then
                    BufferContext()
                end
            end;
            _Deserialize = function(Buffer, Context)
                local Size = NumberDeserialize(Buffer, Context)
                local Array = table.create(Size)
                local CaptureInto = (Context and Context.CaptureInto or nil)

                if (CaptureInto) then
                    CaptureInto[Context.CaptureValue] = Array
                    Context.CaptureInto = nil
                end

                for Index = 1, Size do
                    Array[Index] = Deserializer(Buffer, Context)
                end

                if (IsFrozen) then
                    table.freeze(Array)
                end

                return Array
            end;
        }
    end

    return {
        _Serialize = function(Buffer, Array, Context)
            local BufferContext = Buffer.Context

            if (BufferContext) then
                BufferContext("Array(OfType)")
            end

            DynamicUIntSerialize(Buffer, #Array, Context)

            for _, Value in Array do
                Serializer(Buffer, Value, Context)
            end

            if (BufferContext) then
                BufferContext()
            end
        end;
        _Deserialize = function(Buffer, Context)
            local Size = DynamicUIntDeserialize(Buffer, Context)
            local Array = table.create(Size)
            local CaptureInto = (Context and Context.CaptureInto or nil)

            if (CaptureInto) then
                CaptureInto[Context.CaptureValue] = Array
                Context.CaptureInto = nil
            end

            for Index = 1, Size do
                Array[Index] = Deserializer(Buffer, Context)
            end

            if (IsFrozen) then
                table.freeze(Array)
            end

            return Array
        end;
    }
end

return Array