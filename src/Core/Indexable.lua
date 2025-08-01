--!native
--!nonstrict
--!optimize 2

if (not script and Instance) then
    script = game:GetService("ReplicatedFirst").TypeGuard.Core.Indexable
end

local Template = require(script.Parent.Parent._Template)
    type TypeCheckerConstructor<T, P...> = Template.TypeCheckerConstructor<T, P...>
    type SignatureTypeChecker = Template.SignatureTypeChecker
    type FunctionalArg<T> = Template.FunctionalArg<T>
    type TypeChecker<ExtensionClass, Primitive> = Template.TypeChecker<ExtensionClass, Primitive>

local Util = require(script.Parent.Parent.Util)
    local AssertIsTypeBase = Util.AssertIsTypeBase
    local ExpectType = Util.ExpectType
    local Expect = Util.Expect

local TableUtil = require(script.Parent.Parent.Parent.TableUtil).WithFeatures()
    local IsPureArray = TableUtil.Array.IsPureArray
    local IsOrdered = TableUtil.Array.IsOrdered
    local IsPureMap = TableUtil.Map.IsPureMap
    local MergeDeep = TableUtil.Map.MergeDeep
    local Merge = TableUtil.Map.Merge

local Number = require(script.Parent.Number)
    local DynamicUInt = Number():Integer(32, false):Positive():Dynamic()
    local DynamicIndex = Number(1, 0xFFFFFFFF):Integer():Dynamic()

local ValueCache = require(script.Parent.ValueCache)

export type IndexableTypeChecker = TypeChecker<IndexableTypeChecker, {any}> & {
    ContainsValueOfType: ((self: IndexableTypeChecker, Checker: FunctionalArg<SignatureTypeChecker>) -> (IndexableTypeChecker));
    ContainsKeyOfType: ((self: IndexableTypeChecker, Checker: FunctionalArg<SignatureTypeChecker>) -> (IndexableTypeChecker));
    CheckMetatable: ((self: IndexableTypeChecker, Checker: FunctionalArg<SignatureTypeChecker>) -> (IndexableTypeChecker));
    UnmapStructure: ((self: IndexableTypeChecker, Unmapper: FunctionalArg<(any?) -> (any?)>) -> (IndexableTypeChecker));
    MapStructure: ((self: IndexableTypeChecker, StructureChecker: FunctionalArg<SignatureTypeChecker>, Mapper: FunctionalArg<(any?) -> (any?)>) -> (IndexableTypeChecker));
    OfValueType: ((self: IndexableTypeChecker, Checker: FunctionalArg<SignatureTypeChecker>) -> (IndexableTypeChecker));
    OfStructure: ((self: IndexableTypeChecker, Structure: FunctionalArg<{[any]: SignatureTypeChecker}>) -> (IndexableTypeChecker));
    IsOrdered: ((self: IndexableTypeChecker, AscendingOrDescendingOrEither: FunctionalArg<boolean>?) -> (IndexableTypeChecker));
    PureArray: ((self: IndexableTypeChecker, ValueType: FunctionalArg<SignatureTypeChecker>) -> (IndexableTypeChecker));
    OfKeyType: ((self: IndexableTypeChecker, Checker: FunctionalArg<SignatureTypeChecker>) -> (IndexableTypeChecker));
    IsFrozen: ((self: IndexableTypeChecker) -> (IndexableTypeChecker));
    PureMap: ((self: IndexableTypeChecker, KeyType: FunctionalArg<SignatureTypeChecker>?, ValueType: FunctionalArg<SignatureTypeChecker>?) -> (IndexableTypeChecker));
    MinSize: ((self: IndexableTypeChecker, MinSize: FunctionalArg<number>) -> (IndexableTypeChecker));
    MaxSize: ((self: IndexableTypeChecker, MaxSize: FunctionalArg<number>) -> (IndexableTypeChecker));
    OfClass: ((self: IndexableTypeChecker, Class: FunctionalArg<{[string]: any}>) -> (IndexableTypeChecker));
    Strict: ((self: IndexableTypeChecker) -> (IndexableTypeChecker));
    And: ((self: IndexableTypeChecker, Other: FunctionalArg<IndexableTypeChecker>) -> (IndexableTypeChecker));

    Similarity: ((self: IndexableTypeChecker, Value: any) -> (number));
    GroupKV: ((self: IndexableTypeChecker) -> (IndexableTypeChecker));
}

-- Todo: move arrays support into this?

type Constructor = ((Structure: {SignatureTypeChecker}?) -> (IndexableTypeChecker)) & -- OfStructure
                   ((KeyType: SignatureTypeChecker, ValueType: SignatureTypeChecker?) -> (IndexableTypeChecker)) -- OfKeyType, OfValueType

local function _SupportsArrayIndex(Type)
    return (Type:Check(1) and not Type:Check(1.1) and not Type:Check(0))
end

local function _SupportsNonArrayIndex(Type)
    if (Type.Name == "Or") then
        local IsATypeIn = Type:GetConstraint("IsATypeIn")

        if (IsATypeIn) then
            for _, SubType in IsATypeIn[1] do
                if (not _SupportsArrayIndex(SubType)) then
                    return true
                end
            end
        end

        return false
    end

    return (not _SupportsArrayIndex(Type))
end

local Indexable: Constructor, IndexableClass = Template.Create("Structure")
IndexableClass._Indexable = true
IndexableClass._TypeOf = {"table"}
IndexableClass.Name = "table"

local Any

local function _InitAny()
    Any = Any or ValueCache((require(script.Parent.Parent.Roblox.Any) :: any)())
end

function IndexableClass:_Initial(TargetStructure)
    local Type = typeof(TargetStructure)

    -- Some structures are userdata & typeof will report their name directly. Serializers will overwrite 'Type' with the name.
    local ExpectedType = self.Name

    if (Type == ExpectedType) then
        return true
    end

    return false, `Expected {ExpectedType}, got {Type}`
end

local function _OfStructure(SelfRef, StructureToCheck, SubTypes)
    -- Check all fields which should be in the structure exist and the type check for each passes.
    for Key, SubType in SubTypes do
        local Success, SubMessage = SubType:_Check(StructureToCheck[Key])

        if (not Success) then
            return false, `[Key '{Key}'] {SubMessage}`
        end
    end

    -- Check there are no extra fields which shouldn't be in the structure.
    if (SelfRef._Strict and type(StructureToCheck) == "table") then
        for Key in StructureToCheck do
            if (not SubTypes[Key]) then
                return false, `[Key '{Key}'] unexpected (strict)`
            end
        end
    end

    return true
end

--- Ensures every key that exists in the subject also exists in the structure passed, optionally strict i.e. extra keys which don't exist in the spec are rejected.
function IndexableClass:OfStructure(SubTypes)
    ExpectType(SubTypes, Expect.SOMETHING, 1)

    for Index, Value in SubTypes do
        AssertIsTypeBase(Value, Index)
    end

    if (not table.isfrozen(SubTypes)) then
        table.freeze(SubTypes)
    end

    if (SubTypes[1] and next(SubTypes, #SubTypes) ~= nil) then
        error("Mix of array and map definition not supported in OfStructure", 2)
    end

    return self:_AddConstraint(true, "OfStructure", _OfStructure, SubTypes)
end

local function _OfValueType(_, Target, SubType)
    local Check = SubType._Check

    for Index, Value in Target do
        local Success, SubMessage = Check(SubType, Value)
        if (not Success) then
            return false, `[OfValueType: Key '{Index}'] {SubMessage}`
        end
    end

    return true
end

--- For all values in the passed table, they must satisfy the TypeChecker passed to this constraint.
function IndexableClass:OfValueType(SubType)
    if (type(SubType) ~= "function") then
        AssertIsTypeBase(SubType, 1)
    end

    return self:_AddConstraint(true, "OfValueType", _OfValueType, SubType)
end

local function _PureArray(_, Target)
    if (IsPureArray(Target) or next(Target) == nil) then
        return true
    end

    return false, "Expected a pure array"
end

--- Ensures the indexable is a pure array, i.e. contiguous positive integers starting at 1 as keys.
function IndexableClass:PureArray(ValueType)
    if (ValueType) then
        AssertIsTypeBase(ValueType, 1)
    end

    if (self:GetConstraint("PureMap")) then
        error("Cannot use PureArray on an Indexable already defined as a PureMap", 2)
    end

    if (ValueType == nil) then
        _InitAny()
        ValueType = Any
    end

    return self:_AddConstraint(true, "PureArray", _PureArray)
            :OfKeyType(DynamicIndex)
            :OfValueType(ValueType)
end

local function _PureMap(_, Target)
    if (IsPureMap(Target) or next(Target) == nil) then
        return true
    end

    return false, "Expected a pure map"
end

--- Ensures the indexable is a pure map, i.e. no array keys are present.
function IndexableClass:PureMap(KeyType, ValueType)
    if (ValueType) then
        AssertIsTypeBase(ValueType, 1)
    end

    if (KeyType) then
        AssertIsTypeBase(KeyType, 1)
    end

    if (self:GetConstraint("PureArray")) then
        error("Cannot use PureMap on an Indexable already defined as a PureArray", 2)
    end

    if (ValueType == nil) then
        _InitAny()
        ValueType = Any
    end

    if (KeyType == nil) then
        _InitAny()
        KeyType = DynamicIndex
    end

    return self:_AddConstraint(true, "PureMap", _PureMap)
            :OfKeyType(KeyType)
            :OfValueType(ValueType)
end

local function _OfKeyType(_, Target, SubType)
    local Check = SubType._Check

    for Key in Target do
        local Success, SubMessage = Check(SubType, Key)

        if (not Success) then
            return false, `[OfKeyType: Key '{Key}'] {SubMessage}`
        end
    end

    return true
end

--- For all keys in the passed table, they must satisfy the TypeChecker passed to this constraint.
function IndexableClass:OfKeyType(SubType)
    if (type(SubType) ~= "function") then
        AssertIsTypeBase(SubType, 1)
    end

    return self:_AddConstraint(true, "OfKeyType", _OfKeyType, SubType)
end

local function _IsOrdered(_, Target, AscendingOrDescendingOrEither)
    if (IsOrdered(Target, AscendingOrDescendingOrEither)) then
        return true
    end

    return false, "Array values were not ordered"
end

--- Checks if an array is ordered.
function IndexableClass:IsOrdered(AscendingOrDescendingOrEither)
    assert(self:GetConstraint("PureArray"), "IsOrdered can only be used on pure arrays")

    if (AscendingOrDescendingOrEither ~= nil) then
        ExpectType(AscendingOrDescendingOrEither, Expect.BOOLEAN_OR_FUNCTION, 1)
    end

    return self:_AddConstraint(true, "IsOrdered", _IsOrdered, AscendingOrDescendingOrEither)
end

--- Merges two Object checkers together. Fields in the latter overwrites fields in the former.
function IndexableClass:And(Other)
    AssertIsTypeBase(Other, 1)
    assert(IndexableClass.And, "Conjunction is not a structural checker")
    assert(IndexableClass.And == self.And, "Conjunction is not an Indexable")

    local SelfOfStructure, Index = self:GetConstraint("OfStructure")
    assert(SelfOfStructure, "OfStructure constraint not present on self")

    local OtherOfStructure = Other:GetConstraint("OfStructure")
    assert(OtherOfStructure, "OfStructure constraint not present on conjunction")

    self = self:Modify({
        _ActiveConstraints = {
            [Index] = {
                Args = {
                    [1] = function(ExistingOfStructureArgs)
                        return MergeDeep(ExistingOfStructureArgs, OtherOfStructure[1], true)
                    end;
                };
            };
        };
    })

    return self
end

--- Strict i.e. no extra key-value pairs than what is explicitly specified when using OfStructure.
function IndexableClass:Strict()
    assert(self:GetConstraint("OfStructure") or self._MapStructure, "Strict can only be used on Indexables with OfStructure or MapStructure defined")

    return self:Modify({
        _Strict = true;
    })
end

local function _IsFrozen(_, Target)
    if (table.isfrozen(Target)) then
        return true
    end

    return false, "Table was not frozen"
end

--- Checks if an object is frozen.
function IndexableClass:IsFrozen()
    return self:_AddConstraint(true, "IsFrozen", _IsFrozen)
end

local function _CheckMetatable(_, Target, Checker)
    local Success, Message = Checker:_Check(getmetatable(Target))

    if (Success) then
        return true
    end

    return false, `[Metatable] {Message}`
end

--- Checks an object's metatable.
function IndexableClass:CheckMetatable(Checker)
    AssertIsTypeBase(Checker, 1)
    assert(
        (
            Checker:GetConstraint("IsAValueIn") or
            Checker:GetConstraint("IsAKeyIn") or
            Checker:GetConstraint("Equals")
        ),
        "Checker must have IsAValueIn, IsAKeyIn, or Equals defined"
    )

    return self:_AddConstraint(false, "CheckMetatable", _CheckMetatable, Checker)
end

--- Checks if an object's __index points to the specified class.
function IndexableClass:OfClass(Class)
    ExpectType(Class, Expect.TABLE, 1)
    assert(Class.__index, "Class must have an __index")

    return self:CheckMetatable(Indexable():Equals(Class))
end

local function _ContainsValueOfType(_, Target, Checker)
    local Check = Checker._Check

    for _, Value in Target do
        local Success = Check(Checker, Value)

        if (Success) then
            return true
        end
    end

    return false, `[ContainsValueOfType] did not contain any values which satisfied {Checker}`
end

--- Checks if an object contains a value which satisfies the given TypeChecker.
function IndexableClass:ContainsValueOfType(Checker)
    AssertIsTypeBase(Checker, 1)

    return self:_AddConstraint(false, "ContainsValueOfType", _ContainsValueOfType, Checker)
end

local function _ContainsKeyOfType(_, Target, Checker)
    local Check = Checker._Check

    for Key in Target do
        local Success = Check(Checker, Key)

        if (Success) then
            return true
        end
    end

    return false, `[ContainsKeyOfType] did not contain any values which satisfied {Checker}`
end

--- Checks if an object contains a value which satisfies the given TypeChecker.
function IndexableClass:ContainsKeyOfType(Checker)
    AssertIsTypeBase(Checker, 1)

    return self:_AddConstraint(false, "ContainsKeyOfType", _ContainsKeyOfType, Checker)
end

local function _MinSize(self, Target, MinSize)
    if (self:GetConstraint("PureArray")) then
        if (#Target < MinSize) then
            return false, `[MinSize] expected at least {MinSize} elements, got {#Target}`
        end

        return true
    end

    local Count = 0

    for _ in Target do
        Count += 1
    end

    if (Count < MinSize) then
        return false, `[MinSize] expected at least {MinSize} elements, got {Count}`
    end

    return true
end

function IndexableClass:MinSize(MinSize)
    ExpectType(MinSize, Expect.NUMBER_OR_FUNCTION, 1)

    return self:_AddConstraint(true, "MinSize", _MinSize, MinSize)
end

local function _MaxSize(self, Target, MaxSize)
    if (self:GetConstraint("PureArray")) then
        if (#Target > MaxSize) then
            return false, `[MaxSize] expected at most {MaxSize} elements, got {Target}`
        end

        return true
    end

    local Count = 0

    for _ in Target do
        Count += 1
    end

    if (Count > MaxSize) then
        return false, `[MaxSize] expected at most {MaxSize} elements, got {Count}`
    end

    return true
end

function IndexableClass:MaxSize(MaxSize)
    ExpectType(MaxSize, Expect.NUMBER_OR_FUNCTION, 1)

    return self:_AddConstraint(true, "MaxSize", _MaxSize, MaxSize)
end

function IndexableClass:OfLength(Length: number)
    ExpectType(Length, Expect.NUMBER, 1)

    return self:MinSize(Length):MaxSize(Length)
end

local Original = IndexableClass.RemapDeep
function IndexableClass:RemapDeep(Type, Mapper, Recursive)
    local Copy = Original(self, Type, Mapper, Recursive)
        local MapStructure = Copy._MapStructure

    -- Todo: change to Modify?
    if (MapStructure and Recursive and MapStructure[1].RemapDeep) then
        Copy = Copy:Modify({
            _MapStructure = {
                [1] = function(Value)
                    return Mapper(Value:RemapDeep(Type, Mapper, Recursive))
                end;
            }
        })
    end

    return Copy
end

function IndexableClass:MapStructure(SubStructure, Mapper)
    return self:Modify({
        _MapStructure = function(_)
            return {SubStructure, Mapper}
        end;
    })
end

function IndexableClass:UnmapStructure(Mapper)
    return self:Modify({
        _UnmapStructure = function(_)
            return Mapper
        end;
    })
end

function IndexableClass:Similarity(Value)
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

local function EmptyFunction()
end

function IndexableClass:_UpdateSerialize()
    local HasFunctionalConstraints = self:_HasFunctionalConstraints()
    local MapStructure = self._MapStructure

    local OfStructure = self:GetConstraint("OfStructure")
    local OfValueType = self:GetConstraint("OfValueType")
    local OfKeyType = self:GetConstraint("OfKeyType")

    local MapStructureFunction = (MapStructure and MapStructure[2] or function(Value)
        return Value
    end)

    local UnmapStructureFunction = (self._Unmap or self._UnmapStructure or function(Value)
        return Value
    end)

    local CheckMetatable = self:GetConstraint("CheckMetatable")
        local CheckMetatableValue = (CheckMetatable and CheckMetatable[1])
            local CheckMetatableSerialize = (CheckMetatableValue and CheckMetatableValue._Serialize)
            local CheckMetatableDeserialize = (CheckMetatableValue and CheckMetatableValue._Deserialize)

    local function SerializeMetaProperties(Buffer, Value, Context)
        -- 0 = not a table.
        -- 1 = table + frozen.
        -- 2 = table + not frozen.
        -- 3 = hopefully Luau adds no more hidden table attributes but if it does, can be used to signify a forward-compatible extension. 

        if (type(Value) == "table") then
            Buffer.WriteUInt(2, table.isfrozen(Value) and 1 or 2)

            if (CheckMetatableSerialize) then
                CheckMetatableSerialize(Buffer, getmetatable(Value), Context)
            end
        else
            Buffer.WriteUInt(2, 0)
        end
    end

    local function DeserializeMetaProperties(Buffer, Indexable, Context)
        local Tag = Buffer.ReadUInt(2)

        if (Tag > 0) then
            local Metatable = (CheckMetatableDeserialize and CheckMetatableDeserialize(Buffer, Context, Indexable))
    
            if (Metatable) then
                setmetatable(Indexable, Metatable)
            end
    
            if (Tag == 1) then
                table.freeze(Indexable)
            end
        end
    end

    local AnySerializeDeserialize = {
        _Serialize = function(Buffer, Value, Context)
            local BufferContext = Buffer.Context

            if (BufferContext) then
                BufferContext("Object(Any)")
            end

            if (MapStructureFunction) then
                Value = MapStructureFunction(Value)
            end

            local Serialize = (Context and Context.AnySerialize or nil)

            if (Serialize == nil) then
                _InitAny()
                Serialize = Any._Serialize

                Context = Merge(Context or {}, {
                    AnySerialize = Serialize;
                })
            end

            Serialize(Buffer, Value, Context)
            SerializeMetaProperties(Buffer, Value, Context)

            if (BufferContext) then
                BufferContext()
            end
        end;
        _Deserialize = function(Buffer, Context)
            local Deserialize = (Context and Context.AnyDeserialize or nil)

            if (Deserialize == nil) then
                _InitAny()
                Deserialize = Any._Deserialize

                Context = Merge(Context or {}, {
                    AnyDeserialize = Deserialize;
                })
            end

            local Result

            if (Deserialize) then
                local Temp = Deserialize(Buffer, Context)
                Result = (UnmapStructureFunction and UnmapStructureFunction(Temp) or Temp)
            end

            DeserializeMetaProperties(Buffer, Result, Context)
            return Result
        end;
    }

    if (HasFunctionalConstraints) then
        DeserializeMetaProperties = EmptyFunction
        SerializeMetaProperties = EmptyFunction
        return AnySerializeDeserialize
    end

    local OfValueTypeChecker = (OfValueType and OfValueType[1] or nil)
        local ValueDeserialize = (OfValueTypeChecker and OfValueTypeChecker._Deserialize or nil)
        local ValueSerialize = (OfValueTypeChecker and OfValueTypeChecker._Serialize or nil)

    local OfKeyTypeChecker = (OfKeyType and OfKeyType[1] or nil)
        local KeyDeserialize = (OfKeyTypeChecker and OfKeyTypeChecker._Deserialize or nil)
        local KeySerialize = (OfKeyTypeChecker and OfKeyTypeChecker._Serialize or nil)

    local MaxSize = self:GetConstraint("MaxSize")
    local MinSize = self:GetConstraint("MinSize")

    local SizeSerializer = (
        (MaxSize or MinSize) and
        Number(MinSize and MinSize[1] or 0, MaxSize and MaxSize[1] or 0xFFFFFFFF):Integer() or
        DynamicUInt
    )
    local SizeDeserialize = SizeSerializer._Deserialize
    local SizeSerialize = SizeSerializer._Serialize

    local StructureDefinition = (MapStructure and MapStructure[1] and MapStructure[1]:GetConstraint("OfStructure") and MapStructure[1]:GetConstraint("OfStructure")[1]) or (OfStructure and OfStructure[1])

    if (StructureDefinition) then
        StructureDefinition = table.clone(StructureDefinition)
    end

    local HasArrayKeys = (OfKeyTypeChecker ~= nil and _SupportsArrayIndex(OfKeyTypeChecker))
    local HasAmbiguousMapKeys = ((self:GetConstraint("PureMap") or (HasArrayKeys or (OfKeyTypeChecker ~= nil and _SupportsNonArrayIndex(OfKeyTypeChecker)))) and not self:GetConstraint("PureArray") and not self._Strict)
    local HasUnambiguousMapKeys = pcall(table.sort, StructureDefinition)

    local UnambiguousKeyToDeserializeFunction
    local UnambiguousKeyToSerializeFunction
    local UnambiguousIndexToKey = {}

    if (HasUnambiguousMapKeys) then
        UnambiguousKeyToSerializeFunction = table.clone(StructureDefinition)
        UnambiguousKeyToDeserializeFunction = table.clone(StructureDefinition)

        for Key, Value in StructureDefinition do
            table.insert(UnambiguousIndexToKey, Key)
            UnambiguousKeyToSerializeFunction[Key] = Value._Serialize
            UnambiguousKeyToDeserializeFunction[Key] = Value._Deserialize
        end
    end

    if (StructureDefinition == nil and (OfKeyTypeChecker == nil or OfValueTypeChecker == nil)) then
        DeserializeMetaProperties = EmptyFunction
        SerializeMetaProperties = EmptyFunction
        return AnySerializeDeserialize
    end

    --[[ print(
        "Construction:\n",
        `\tArray Part: {HasArrayKeys}\n`,
        `\tUnambiguous Map Part: {HasUnambiguousMapKeys}\n`,
        `\tAmbiguous Map Part: {HasAmbiguousMapKeys}\n`
    ) ]]

    -- This library considers three non-mutually-exclusive serialization categories to an indexable:
    -- 1. Array part (the Luau array / non-hashmap part of a table).
    -- 2. Unambiguous map part (the Luau hashmap part of a table where keys are known and sortable).
    -- 3. Ambiguous map part (the Luau hashmap part of a table where keys are not known).
    -- Each has a different optimization approach during serialization and deserialization.

    return {
        _Serialize = function(Buffer, Value, Context)
            local BufferContext = Buffer.Context

            if (BufferContext) then
                BufferContext("Indexable")
            end

            if (MapStructureFunction) then
                Value = MapStructureFunction(Value)
            end

            local ArraySize

            if (HasArrayKeys) then
                if (BufferContext) then
                    BufferContext("Indexable(Array)")
                end

                ArraySize = #Value
                SizeSerialize(Buffer, ArraySize, Context)

                for Index = 1, ArraySize do
                    -- print("\tArray Key", Index)
                    ValueSerialize(Buffer, Value[Index], Context)
                end

                if (BufferContext) then
                    BufferContext()
                end
            end

            if (HasUnambiguousMapKeys) then
                if (BufferContext) then
                    BufferContext("Indexable(Unambiguous)")
                end

                if (ArraySize) then
                    for _, Key in UnambiguousIndexToKey do
                        if (type(Key) == "number" and (Key >= 1 and Key <= ArraySize)) then
                            continue
                        end

                        -- print("\tUnambiguous Key[2]", Key)
                        UnambiguousKeyToSerializeFunction[Key](Buffer, Value[Key], Context)
                    end
                else
                    for _, Key in UnambiguousIndexToKey do
                        -- print("\tUnambiguous Key[1]", Key)
                        UnambiguousKeyToSerializeFunction[Key](Buffer, Value[Key], Context)
                    end
                end

                if (BufferContext) then
                    BufferContext()
                end
            end

            if (HasAmbiguousMapKeys) then
                if (BufferContext) then
                    BufferContext("Indexable(Ambiguous)")
                end

                if (StructureDefinition or ArraySize) then
                    local Length = 0

                    for Key in Value do
                        if (ArraySize and type(Key) == "number" and (Key >= 1 and Key <= ArraySize)) then
                            continue
                        end

                        if (StructureDefinition and StructureDefinition[Key] ~= nil) then
                            continue
                        end

                        Length += 1
                    end

                    SizeSerialize(Buffer, Length, Context)

                    for Key, Value in Value do
                        if (ArraySize and type(Key) == "number" and (Key >= 1 and Key <= ArraySize)) then
                            continue
                        end

                        if (StructureDefinition and StructureDefinition[Key] ~= nil) then
                            continue
                        end

                        -- print("\tAmbiguous Key[2]", StructureDefinition, Key)
                        KeySerialize(Buffer, Key, Context)
                        ValueSerialize(Buffer, Value, Context)
                    end
                else
                    local Length = 0

                    for Key in Value do
                        Length += 1
                    end

                    SizeSerialize(Buffer, Length, Context)

                    for Key, Value in Value do
                        -- print("\tAmbiguous Key[1]", Key)
                        KeySerialize(Buffer, Key, Context)
                        ValueSerialize(Buffer, Value, Context)
                    end
                end

                if (BufferContext) then
                    BufferContext()
                end
            end

            SerializeMetaProperties(Buffer, Value, Context)

            if (BufferContext) then
                BufferContext()
            end
        end;
        _Deserialize = function(Buffer, Context)
            local Result

            if (HasArrayKeys) then
                local Size = SizeDeserialize(Buffer, Context)
                Result = table.create(Size)
                local CaptureInto = (Context and Context.CaptureInto or nil)

                if (CaptureInto) then
                    CaptureInto[Context.CaptureValue] = Result
                    Context.CaptureInto = nil
                end

                for Index = 1, Size do
                    Result[Index] = ValueDeserialize(Buffer, Context)
                end
            end

            if (HasUnambiguousMapKeys) then
                if (Result == nil) then
                    Result = {}
                    local CaptureInto = (Context and Context.CaptureInto or nil)

                    if (CaptureInto) then
                        CaptureInto[Context.CaptureValue] = Result
                        Context.CaptureInto = nil
                    end
                end

                for _, Key in UnambiguousIndexToKey do
                    Result[Key] = UnambiguousKeyToDeserializeFunction[Key](Buffer, Context)
                end
            end

            if (HasAmbiguousMapKeys) then
                if (Result == nil) then
                    Result = {}
                    local CaptureInto = (Context and Context.CaptureInto or nil)

                    if (CaptureInto) then
                        CaptureInto[Context.CaptureValue] = Result
                        Context.CaptureInto = nil
                    end
                end

                local Length = SizeDeserialize(Buffer, Context)

                for Index = 1, Length do
                    Result[KeyDeserialize(Buffer, Context)] = ValueDeserialize(Buffer, Context)
                end
            end

            if (UnmapStructureFunction) then
                Result = UnmapStructureFunction(Result)
            end

            DeserializeMetaProperties(Buffer, Result, Context)
            return Result
        end;
    }
end

function IndexableClass:InitialConstraint(X, Y)
    if (Y) then
        -- Use OfKeyType and OfValueType constraints.
        return self:OfKeyType(X):OfValueType(Y)
    end

    if (X) then
        -- Use OfStructure constraint.
        return self:OfStructure(X)
    end

    -- Don't use any constraints.
    return self
end

--[[ local function TestClass()
    local Test = {}
    Test.__index = Test
    
    function Test.new()
        return setmetatable({
            X = 1;
            Y = 2;
        }, Test)
    end
    
    function Test:Change()
        self.X *= 2
        self.Y *= 2
        return self
    end

    return Test
end

task.defer(function()
    local Or = require(script.Parent.Or)

    local Test1 = TestClass()
    local Test2 = TestClass()

    local TestInstance1 = Test1.new()
    local TestInstance2 = table.freeze(Test2.new())

    local Metatables = Or():IsAValueIn({Test1, Test2})

    local AHHH = Indexable({
        X = Number():Integer(8, false);
        Y = Number():Integer(8, false);
    }):CheckMetatable(Metatables)

    local DS1 = AHHH:Deserialize(AHHH:Serialize(TestInstance1))
    local DS2 = AHHH:Deserialize(AHHH:Serialize(TestInstance2))
    print(getmetatable(DS1) == Test1, table.isfrozen(DS1))
    print(getmetatable(DS2) == Test2, table.isfrozen(DS2))
end) ]]

--[[ task.defer(function()
    local String = require(script.Parent.String)
    local Or = require(script.Parent.Or)

    local ArrayIndex = Number(1, 0xFFFFFFFF):Integer():Dynamic()

    -- Array Part: true
    -- Unambiguous Map Part: false
    -- Ambiguous Map Part: false
    print("-------------------Array")
    local Serializer = Indexable(ArrayIndex, String()):PureArray()
    local Serialized = Serializer:Serialize({"Hello", "World"})
    print("Serialized:", buffer.tostring(Serialized))
    print("Deserialized:", Serializer:Deserialize(Serialized))

    -- Array Part: false
    -- Unambiguous Map Part: true
    -- Ambiguous Map Part: false
    print("-------------------Unambiguous")
    Serializer = Indexable():OfStructure({X = String(), Y = String()})
    Serialized = Serializer:Serialize({X = "Hello", Y = "World"})
    print("Serialized:", buffer.tostring(Serialized))
    print("Deserialized:", Serializer:Deserialize(Serialized))

    -- Array Part: true
    -- Unambiguous Map Part: true
    -- Ambiguous Map Part: false
    print("-------------------Array, Unambiguous")
    Serializer = Indexable(ArrayIndex, String()):OfStructure({[300] = String()}):PureArray()
    Serialized = Serializer:Serialize({"X", "Y", "Z", [300] = "Hello"})
    print("Serialized:", buffer.tostring(Serialized))
    print("Deserialized:", Serializer:Deserialize(Serialized))

    -- Array Part: false
    -- Unambiguous Map Part: false
    -- Ambiguous Map Part: true
    print("-------------------Ambiguous")
    Serializer = Indexable(String(), String())
    Serialized = Serializer:Serialize({X = "X", Y = "Y"})
    print("Serialized:", buffer.tostring(Serialized))
    print("Deserialized:", Serializer:Deserialize(Serialized))

    -- Array Part: true
    -- Unambiguous Map Part: false
    -- Ambiguous Map Part: true
    print("-------------------Array, Ambiguous")
    Serializer = Indexable(Or(ArrayIndex, String()), String())
    Serialized = Serializer:Serialize({X = "X", [1] = "Y", [5] = "Z"})
    print("Serialized:", buffer.tostring(Serialized))
    print("Deserialized:", Serializer:Deserialize(Serialized))

    -- Array Part: false
    -- Unambiguous Map Part: true
    -- Ambiguous Map Part: true
    -- *i.e. must contain X and Y, but can also contain ambiguous key-value pairs.
    print("-------------------Unambiguous, Ambiguous")
    Serializer = Indexable(Or(String(), Number()), String()):OfStructure({X = String(), Y = String()})
    Serialized = Serializer:Serialize({X = "X", Y = "Y", PQR = "PQR", [1.23] = "Ok"})
    print("Serialized:", buffer.tostring(Serialized))
    print("Deserialized:", Serializer:Deserialize(Serialized))

    -- Array Part: true
    -- Unambiguous Map Part: true
    -- Ambiguous Map Part: true
    -- *i.e. must contain X and Y, but can also contain ambiguous key-value pairs and array key-value pairs.
    print("-------------------Array, Unambiguous, Ambiguous")
    Serializer = Indexable(Or(ArrayIndex, String()), String()):OfStructure({X = String(), Y = String()})
    Serialized = Serializer:Serialize({X = "X", Y = "Y", PQR = "PQR", [1] = "Ok"})
    print("Serialized:", buffer.tostring(Serialized))
    print("Deserialized:", Serializer:Deserialize(Serialized))

    print("-------------------")
end) ]]

return Indexable