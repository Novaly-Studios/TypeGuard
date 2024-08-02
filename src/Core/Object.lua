--!native
--!optimize 2

if (not script) then
    script = game:GetService("ReplicatedFirst").TypeGuard.Core.Object
end

local Template = require(script.Parent.Parent:WaitForChild("_Template"))
    type TypeCheckerConstructor<T, P...> = Template.TypeCheckerConstructor<T, P...>
    type SignatureTypeChecker = Template.SignatureTypeChecker
    type FunctionalArg<T> = Template.FunctionalArg<T>
    type TypeChecker<ExtensionClass, Primitive> = Template.TypeChecker<ExtensionClass, Primitive>
    type SelfReturn<T, P...> = Template.SelfReturn<T, P...>

local Util = require(script.Parent.Parent:WaitForChild("Util"))
    local StructureStringMT = Util.StructureStringMT
    local AssertIsTypeBase = Util.AssertIsTypeBase
    local ExpectType = Util.ExpectType
    local Expect = Util.Expect

local TableUtil = require(script.Parent.Parent.Parent:WaitForChild("TableUtil"))
    local Merge = TableUtil.Map.Merge
    local Map = TableUtil.Map.Map

type StructureTypeChecker = TypeChecker<StructureTypeChecker, {[any]: any}> & {
    ContainsValueOfType: ((self: StructureTypeChecker, Checker: FunctionalArg<SignatureTypeChecker>) -> (StructureTypeChecker));
    ContainsKeyOfType: ((self: StructureTypeChecker, Checker: FunctionalArg<SignatureTypeChecker>) -> (StructureTypeChecker));
    CheckMetatable: ((self: StructureTypeChecker, Checker: FunctionalArg<SignatureTypeChecker>) -> (StructureTypeChecker));
    UnmapStructure: ((self: StructureTypeChecker, Unmapper: FunctionalArg<(any?) -> (any?)>) -> (StructureTypeChecker));
    MapStructure: ((self: StructureTypeChecker, StructureChecker: FunctionalArg<SignatureTypeChecker>, Mapper: FunctionalArg<(any?) -> (any?)>) -> (StructureTypeChecker));
    OfValueType: ((self: StructureTypeChecker, Checker: FunctionalArg<SignatureTypeChecker>) -> (StructureTypeChecker));
    OfStructure: ((self: StructureTypeChecker, Structure: FunctionalArg<{[any]: SignatureTypeChecker}>) -> (StructureTypeChecker));
    OfKeyType: ((self: StructureTypeChecker, Checker: FunctionalArg<SignatureTypeChecker>) -> (StructureTypeChecker));
    IsFrozen: ((self: StructureTypeChecker) -> (StructureTypeChecker));
    MinSize: ((self: StructureTypeChecker, MinSize: FunctionalArg<number>) -> (StructureTypeChecker));
    MaxSize: ((self: StructureTypeChecker, MaxSize: FunctionalArg<number>) -> (StructureTypeChecker));
    OfClass: ((self: StructureTypeChecker, Class: FunctionalArg<{[string]: any}>) -> (StructureTypeChecker));
    Strict: ((self: StructureTypeChecker) -> (StructureTypeChecker));
    And: ((self: StructureTypeChecker, Other: FunctionalArg<StructureTypeChecker>) -> (StructureTypeChecker));

    Similarity: ((self: StructureTypeChecker, Value: any) -> (number));
    GroupKV: ((self: StructureTypeChecker) -> (StructureTypeChecker));
};

local Structure: ((Structure: FunctionalArg<{[any]: SignatureTypeChecker}?>) -> (StructureTypeChecker)), StructureClass = Template.Create("Structure")
StructureClass._TypeOf = {"table"}

function StructureClass:_Initial(TargetStructure)
    local Type = typeof(TargetStructure)

    if (Type == "table") then
        -- This is fully reliable but uncomfortably slow, and therefore disabled for the meanwhile.
        --[[
            for Key in TargetStructure do
                if (typeof(Key) == "number") then
                    return false, "Incorrect key type: number"
                end
            end
        ]]

        -- This will catch the majority of cases.
        if (rawget(TargetStructure, 1) == nil) then
            return true
        end

        return false, "Incorrect key type: numeric index [1]"
    end

    -- Some "objects" are userdata & typeof will report their name directly. Serializers will overwrite 'Type' with the name.
    if (Type == self.Type) then
        return true
    end

    return false, `Expected table, got {Type}`
end

--- Ensures every key that exists in the subject also exists in the structure passed, optionally strict i.e. no extra key-value pairs.
function StructureClass:OfStructure(OriginalSubTypes)
    ExpectType(OriginalSubTypes, Expect.SOMETHING, 1)

    -- Just in case the user does any weird mutation.
    local SubTypesCopy    
    local Type = type(OriginalSubTypes)

    if (Type == "userdata" or Type == "vector") then
        SubTypesCopy = OriginalSubTypes
    else
        ExpectType(OriginalSubTypes, Expect.SOMETHING, 1)
        SubTypesCopy = {}

        for Index, Value in OriginalSubTypes do
            AssertIsTypeBase(Value, Index)
            SubTypesCopy[Index] = Value
        end
    
        setmetatable(SubTypesCopy, StructureStringMT)
    end

    return self:_AddConstraint(true, "OfStructure", function(SelfRef, StructureCopy, SubTypes)
        -- Check all fields which should be in the structure exist and the type check for each passes.
        for Key, Checker in SubTypes do
            local Success, SubMessage = Checker:_Check(StructureCopy[Key])

            if (not Success) then
                return false, `[Key '{Key}'] {SubMessage}`
            end
        end

        -- Check there are no extra fields which shouldn't be in the structure.
        if (SelfRef._Tags.Strict and type(StructureCopy) == "table") then
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
function StructureClass:OfValueType(SubType)
    if (type(SubType) ~= "function") then
        AssertIsTypeBase(SubType, 1)
    end

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
function StructureClass:OfKeyType(SubType)
    if (type(SubType) ~= "function") then
        AssertIsTypeBase(SubType, 1)
    end

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

--- Merges two Object checkers together. Fields in the latter overwrites fields in the former.
function StructureClass:And(Other)
    AssertIsTypeBase(Other, 1)
    assert(StructureClass.And, "Conjunction is not a structural checker.")

    local SelfOfStructure, Index = self:GetConstraint("OfStructure")
    assert(SelfOfStructure, "OfStructure constraint not present on self.")

    local OtherOfStructure = Other:GetConstraint("OfStructure")
    assert(OtherOfStructure, "OfStructure constraint not present on conjunction.")

    local Copy = self:Copy()
    local Merged = table.clone(SelfOfStructure[1])
    for Key, Value in OtherOfStructure[1] do
        Merged[Key] = Value
    end
    Copy._ActiveConstraints = Merge(Copy._ActiveConstraints, {
        [Index] = Merge(Copy._ActiveConstraints[Index], {
            [2] = Map(Copy._ActiveConstraints[Index][2], function(Value, Index)
                return (Index == 2 and Merged or Value)
            end);
        });
    })
    return Copy
end

--- Strict i.e. no extra key-value pairs than what is explicitly specified when using OfStructure.
function StructureClass:Strict()
    return self:_AddTag("Strict")
end

--- Checks if an object is frozen.
function StructureClass:IsFrozen()
    return self:_AddConstraint(true, "IsFrozen", function(_, Target)
        if (table.isfrozen(Target)) then
            return true
        end

        return false, "Table was not frozen"
    end)
end

--- Checks an object's metatable.
function StructureClass:CheckMetatable(Checker)
    AssertIsTypeBase(Checker, 1)

    return self:_AddConstraint(false, "CheckMetatable", function(_, Target, Checker)
        local Success, Message = Checker:_Check(getmetatable(Target))

        if (Success) then
            return true
        end

        return false, `[Metatable] {Message}`
    end, Checker)
end

--- Checks if an object's __index points to the specified class.
function StructureClass:OfClass(Class)
    ExpectType(Class, Expect.TABLE, 1)
    assert(Class.__index, "Class must have an __index")

    return self:CheckMetatable(Structure():Equals(Class))
end

--- Checks if an object contains a value which satisfies the given TypeChecker.
function StructureClass:ContainsValueOfType(Checker)
    AssertIsTypeBase(Checker, 1)

    return self:_AddConstraint(false, "ContainsValueOfType", function(_, Target, Checker)
        for _, Value in Target do
            local Success = Checker:_Check(Value)

            if (Success) then
                return true
            end
        end

        return false, `[ContainsValueOfType] did not contain any values which satisfied {Checker}`
    end, Checker)
end

--- Checks if an object contains a value which satisfies the given TypeChecker.
function StructureClass:ContainsKeyOfType(Checker)
    AssertIsTypeBase(Checker, 1)

    return self:_AddConstraint(false, "ContainsKeyOfType", function(_, Target, Checker)
        for Key in Target do
            local Success = Checker:_Check(Key)

            if (Success) then
                return true
            end
        end

        return false, `[ContainsKeyOfType] did not contain any values which satisfied {Checker}`
    end, Checker)
end

function StructureClass:MinSize(MinSize)
    ExpectType(MinSize, Expect.NUMBER_OR_FUNCTION, 1)

    return self:_AddConstraint(true, "MinSize", function(_, Target, MinSize)
        local Count = 0

        for _ in Target do
            Count += 1
        end

        if (Count < MinSize) then
            return false, `[MinSize] expected at least {MinSize} elements, got {Count}`
        end

        return true
    end, MinSize)
end

function StructureClass:MaxSize(MaxSize)
    ExpectType(MaxSize, Expect.NUMBER_OR_FUNCTION, 1)

    return self:_AddConstraint(true, "MaxSize", function(_, Target, MaxSize)
        local Count = 0

        for _ in Target do
            Count += 1
        end

        if (Count > MaxSize) then
            return false, `[MaxSize] expected at most {MaxSize} elements, got {Count}`
        end

        return true
    end, MaxSize)
end

local Original = StructureClass._MapCheckers
function StructureClass:_MapCheckers(Type, Mapper, Recursive)
    local Copy = Original(self, Type, Mapper, Recursive)
        local MapStructure = Copy._MapStructure

    if (MapStructure and Recursive and MapStructure[1]._MapCheckers) then
        MapStructure[1] = MapStructure[1]:_MapCheckers(Type, Mapper, true)
    end

    return Copy
end

function StructureClass:MapStructure(SubStructure, Mapper)
    self = self:Copy()
    self._MapStructure = {SubStructure, Mapper}
    self:_Changed()
    return self
end

function StructureClass:UnmapStructure(Mapper)
    self = self:Copy()
    self._UnmapStructure = Mapper
    self:_Changed()
    return self
end

function StructureClass:Similarity(Value)
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

    local OfKeyType = self:GetConstraint("OfKeyType")
    if (OfKeyType) then
        local KeyType = OfKeyType[1]
        local KeySimilarity = KeyType.Similarity

        if (type(Value) == "table") then
            for Key in Value do
                Similarity += KeySimilarity and KeySimilarity(KeyType, Key) or 1
            end
        end
    end

    local OfValueType = self:GetConstraint("OfValueType")
    if (OfValueType) then
        local ValueType = OfValueType[1]
        local ValueSimilarity = ValueType.Similarity

        if (type(Value) == "table") then
            for _, Value in Value do
                Similarity += ValueSimilarity and ValueSimilarity(ValueType, Value) or 1
            end
        end
    end

    return Similarity
end

function StructureClass:GroupKV()
    return self:_AddTag("GroupKV")
end

function StructureClass:_UpdateSerialize()
    local MapStructure = self._MapStructure
    local OfStructure = self:GetConstraint("OfStructure")

    if (OfStructure or MapStructure) then
        local Strict = self._Tags.Strict

        if (Strict) then
            local MapStructureFunction = MapStructure and MapStructure[2] or function(Value)
                return Value
            end
            local UnmapStructureFunction = self._Unmap or self._UnmapStructure or function(Value)
                return Value
            end
            local StructureDefinition = (MapStructure and MapStructure[1] and MapStructure[1]:GetConstraint("OfStructure") and MapStructure[1]:GetConstraint("OfStructure")[1]) or (OfStructure and OfStructure[1])
            local HasSingleType = true
            local CommonType = typeof((next(StructureDefinition)))

            for Key in StructureDefinition do
                HasSingleType = (CommonType == typeof(Key))

                if (not HasSingleType) then
                    break
                end
            end

            if (HasSingleType and CommonType == "string") then
                local IndexToKey = {}
                for Key in StructureDefinition do
                    table.insert(IndexToKey, Key)
                end
                table.sort(IndexToKey)

                self._Serialize = function(Buffer, Value, Cache)
                    Value = MapStructureFunction(Value)
                    for Index, Key in IndexToKey do
                        StructureDefinition[Key]._Serialize(Buffer, Value[Key], Cache)
                    end
                end
                self._Deserialize = function(Buffer, Cache)
                    local Result = {}
                    for Index, Key in IndexToKey do
                        Result[Key] = StructureDefinition[Key]._Deserialize(Buffer, Cache)
                    end
                    return UnmapStructureFunction(Result)
                end

                return
            end
        end
    end

    -- Last resort: the defined key and value types, or Any type.
    local OfValueType = self:GetConstraint("OfValueType")
    local OfKeyType = self:GetConstraint("OfKeyType")

    if (not (OfValueType and OfKeyType)) then
        -- TODO: find a way to default to Any type without cyclic module requires.
        self._Serialize = function(_, _, _)
            error("No OfValueType or OfKeyType constraint: cannot serialize")
        end
        self._Deserialize = function(_, _)
            error("No OfValueType or OfKeyType constraint: cannot deserialize")
        end
        return
    end

    local OfValueTypeChecker = OfValueType[1]
        local ValueDeserialize = OfValueTypeChecker._Deserialize
        local ValueSerialize = OfValueTypeChecker._Serialize

    local OfKeyTypeChecker = OfKeyType[1]
        local KeyDeserialize = OfKeyTypeChecker._Deserialize
        local KeySerialize = OfKeyTypeChecker._Serialize

    local MaxSize = self:GetConstraint("MaxSize")
        local MaxSizeValue = MaxSize and math.ceil(math.log(MaxSize[1] + 1, 2)) or 32

    local GroupKV = self._Tags.GroupKV
    if (GroupKV) then
        self._Serialize = function(Buffer, Value, Cache)
            local Length = 0
            for _ in Value do
                Length += 1
            end
            Buffer.WriteUInt(MaxSizeValue, Length)
            for Key in Value do
                KeySerialize(Buffer, Key, Cache)
            end
            for _, Value in Value do
                ValueSerialize(Buffer, Value, Cache)
            end
        end
        self._Deserialize = function(Buffer, Cache)
            local Size = Buffer.ReadUInt(MaxSizeValue)
            local IndexToKey = table.create(Size)
            local Result = {}
            for Index = 1, Size do
                local Key = KeyDeserialize(Buffer, Cache)
                IndexToKey[Index] = Key
                Result[Key] = true
            end
            for Index = 1, Size do
                Result[IndexToKey[Index]] = ValueDeserialize(Buffer, Cache)
            end
            return Result
        end
        return
    end

    self._Serialize = function(Buffer, Value, Cache)
        -- First, write length of table. Then, write each key and value.
        local Length = 0
        for _ in Value do
            Length += 1
        end
        Buffer.WriteUInt(MaxSizeValue, Length)
        for Key, Value in Value do
            KeySerialize(Buffer, Key, Cache)
            ValueSerialize(Buffer, Value, Cache)
        end
    end
    self._Deserialize = function(Buffer, Cache)
        -- First, read length of table. Then, read each key and value pair 'length' times.
        local Result = {}
        for Index = 1, Buffer.ReadUInt(MaxSizeValue) do
            Result[KeyDeserialize(Buffer, Cache)] = ValueDeserialize(Buffer, Cache)
        end
        return Result
    end
end

StructureClass.InitialConstraint = StructureClass.OfStructure

return Structure