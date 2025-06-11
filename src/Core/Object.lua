--!native
--!nonstrict
--!optimize 2

if (not script and Instance) then
    script = game:GetService("ReplicatedFirst").TypeGuard.Core.Object
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
    local MergeDeep = TableUtil.Map.MergeDeep
    local Merge = TableUtil.Map.Merge

local Number = require(script.Parent.Number)

export type IndexableTypeChecker = TypeChecker<IndexableTypeChecker, {any}> & {
    ContainsValueOfType: ((self: IndexableTypeChecker, Checker: FunctionalArg<SignatureTypeChecker>) -> (IndexableTypeChecker));
    ContainsKeyOfType: ((self: IndexableTypeChecker, Checker: FunctionalArg<SignatureTypeChecker>) -> (IndexableTypeChecker));
    CheckMetatable: ((self: IndexableTypeChecker, Checker: FunctionalArg<SignatureTypeChecker>) -> (IndexableTypeChecker));
    UnmapStructure: ((self: IndexableTypeChecker, Unmapper: FunctionalArg<(any?) -> (any?)>) -> (IndexableTypeChecker));
    MapStructure: ((self: IndexableTypeChecker, StructureChecker: FunctionalArg<SignatureTypeChecker>, Mapper: FunctionalArg<(any?) -> (any?)>) -> (IndexableTypeChecker));
    OfValueType: ((self: IndexableTypeChecker, Checker: FunctionalArg<SignatureTypeChecker>) -> (IndexableTypeChecker));
    OfStructure: ((self: IndexableTypeChecker, Structure: FunctionalArg<{[any]: SignatureTypeChecker}>) -> (IndexableTypeChecker));
    OfKeyType: ((self: IndexableTypeChecker, Checker: FunctionalArg<SignatureTypeChecker>) -> (IndexableTypeChecker));
    IsFrozen: ((self: IndexableTypeChecker) -> (IndexableTypeChecker));
    MinSize: ((self: IndexableTypeChecker, MinSize: FunctionalArg<number>) -> (IndexableTypeChecker));
    MaxSize: ((self: IndexableTypeChecker, MaxSize: FunctionalArg<number>) -> (IndexableTypeChecker));
    OfClass: ((self: IndexableTypeChecker, Class: FunctionalArg<{[string]: any}>) -> (IndexableTypeChecker));
    Strict: ((self: IndexableTypeChecker) -> (IndexableTypeChecker));
    And: ((self: IndexableTypeChecker, Other: FunctionalArg<IndexableTypeChecker>) -> (IndexableTypeChecker));

    Similarity: ((self: IndexableTypeChecker, Value: any) -> (number));
    GroupKV: ((self: IndexableTypeChecker) -> (IndexableTypeChecker));
};

-- Todo: move arrays support into this?

type Constructor = ((Structure: SignatureTypeChecker?) -> (IndexableTypeChecker)) & -- OfStructure
                   ((KeyType: SignatureTypeChecker, ValueType: SignatureTypeChecker?) -> (IndexableTypeChecker)) -- OfKeyType, OfValueType

local Indexable: Constructor, IndexableClass = Template.Create("Structure")
IndexableClass._Indexable = true
IndexableClass._TypeOf = {"table"}
IndexableClass.Name = "table"

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

local function _MinSize(_, Target, MinSize)
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

local function _MaxSize(_, Target, MaxSize)
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

--- Serializes keys first, then values second. Not utilized
--- currently, but when Disjunction / Or supports leading
--- serialization via NoLeads tag, this will help save space
--- because the types will be less fragmented.
function IndexableClass:GroupKV()
    return self:Modify({
        _GroupKV = true;
    })
end

local function EmptyFunction()
end

function IndexableClass:_UpdateSerialize()
    local HasFunctionalConstraints = self:_HasFunctionalConstraints()

    local MapStructure = self._MapStructure
    local Strict = self._Strict

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
        local IsTable = (type(Value) == "table")

        if (IsTable) then
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

    local Any

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
                Any = Any or require(script.Parent.ValueCache)((require(script.Parent.Parent.Roblox.Any) :: any)(CheckMetatableValue or nil))
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
                Any = Any or require(script.Parent.ValueCache)((require(script.Parent.Parent.Roblox.Any) :: any)(CheckMetatableValue or nil))
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

    if (HasFunctionalConstraints or not (((MapStructure and MapStructure[1] and MapStructure[1]._Strict)) or (OfStructure and Strict) or (OfValueType and OfKeyType))) then
        DeserializeMetaProperties = EmptyFunction
        SerializeMetaProperties = EmptyFunction
        return AnySerializeDeserialize
    end

    if (OfStructure or MapStructure) then
        local StructureDefinition = (MapStructure and MapStructure[1] and MapStructure[1]:GetConstraint("OfStructure") and MapStructure[1]:GetConstraint("OfStructure")[1]) or (OfStructure and OfStructure[1])
        local IndexToKey = {}

        for Key in StructureDefinition do
            table.insert(IndexToKey, Key)
        end

        local KeysSortable = pcall(table.sort, IndexToKey)

        local KeyToSerializeFunction = table.clone(StructureDefinition)
        for Key, Value in StructureDefinition do
            KeyToSerializeFunction[Key] = Value._Serialize
        end

        local KeyToDeserializeFunction = table.clone(StructureDefinition)
        for Key, Value in StructureDefinition do
            KeyToDeserializeFunction[Key] = Value._Deserialize
        end

        if (KeysSortable) then
            return {
                _Serialize = function(Buffer, Value, Context)
                    local BufferContext = Buffer.Context

                    if (BufferContext) then
                        BufferContext("Object(Unambiguous)")
                    end

                    if (MapStructureFunction) then
                        Value = MapStructureFunction(Value)
                    end

                    for _, Key in IndexToKey do
                        KeyToSerializeFunction[Key](Buffer, Value[Key], Context)
                    end

                    SerializeMetaProperties(Buffer, Value, Context)

                    if (BufferContext) then
                        BufferContext()
                    end
                end;
                _Deserialize = function(Buffer, Context)
                    local Result = {}
                    local CaptureInto = (Context and Context.CaptureInto or nil)

                    if (CaptureInto) then
                        CaptureInto[Context.CaptureValue] = Result
                        Context.CaptureInto = nil
                    end

                    for _, Key in IndexToKey do
                        Result[Key] = KeyToDeserializeFunction[Key](Buffer, Context)
                    end

                    if (UnmapStructureFunction) then
                        Result = UnmapStructureFunction(Result)
                    end

                    DeserializeMetaProperties(Buffer, Result, Context)
                    return Result
                end;
            }
        end

        -- Todo: support for known keys part + any part.
        return AnySerializeDeserialize
    end

    local OfValueTypeChecker = OfValueType[1]
        local ValueDeserialize = OfValueTypeChecker._Deserialize
        local ValueSerialize = OfValueTypeChecker._Serialize

    local OfKeyTypeChecker = OfKeyType[1]
        local KeyDeserialize = OfKeyTypeChecker._Deserialize
        local KeySerialize = OfKeyTypeChecker._Serialize

    local MaxSize = self:GetConstraint("MaxSize")
    local SizeSerializer = (MaxSize and Number(0, MaxSize[1]):Integer() or Number():Integer(32, false):Positive():Dynamic())
        local SizeSerialize = SizeSerializer._Serialize
        local SizeDeserialize = SizeSerializer._Deserialize

    local GroupKV = self._GroupKV

    if (GroupKV) then
        return {
            _Serialize = function(Buffer, Value, Context)
                local BufferContext = Buffer.Context

                if (BufferContext) then
                    BufferContext("Object(GroupKV, OfKeyType, OfValueType)")
                end

                if (MapStructureFunction) then
                    Value = MapStructureFunction(Value)
                end

                local Length = 0

                for _ in Value do
                    Length += 1
                end

                SizeSerialize(Buffer, Length, Context)

                for Key in Value do
                    KeySerialize(Buffer, Key, Context)
                end

                for _, Value in Value do
                    ValueSerialize(Buffer, Value, Context)
                end

                SerializeMetaProperties(Buffer, Value, Context)

                if (BufferContext) then
                    BufferContext()
                end
            end;
            _Deserialize = function(Buffer, Context)
                local Result = {}
                local CaptureInto = (Context and Context.CaptureInto or nil)

                if (CaptureInto) then
                    CaptureInto[Context.CaptureValue] = Result
                    Context.CaptureInto = nil
                end

                local Size = SizeDeserialize(Buffer, Context)
                local IndexToKey = table.create(Size)

                for Index = 1, Size do
                    local Key = KeyDeserialize(Buffer, Context)
                    IndexToKey[Index] = Key
                    Result[Key] = true
                end

                for Index = 1, Size do
                    Result[IndexToKey[Index]] = ValueDeserialize(Buffer, Context)
                end

                if (UnmapStructureFunction) then
                    Result = UnmapStructureFunction(Result)
                end

                DeserializeMetaProperties(Buffer, Result, Context)
                return Result
            end;
        }
    end

    return {
        _Serialize = function(Buffer, Value, Context)
            local BufferContext = Buffer.Context

            if (BufferContext) then
                BufferContext("Object(OfKeyType, OfValueType)")
            end

            if (MapStructureFunction) then
                Value = MapStructureFunction(Value)
            end

            local Length = 0

            for _ in Value do
                Length += 1
            end

            SizeSerialize(Buffer, Length, Context)

            for Key, Value in Value do
                KeySerialize(Buffer, Key, Context)
                ValueSerialize(Buffer, Value, Context)
            end

            SerializeMetaProperties(Buffer, Value, Context)

            if (BufferContext) then
                BufferContext()
            end
        end;
        _Deserialize = function(Buffer, Context)
            local Result = {}
            local CaptureInto = (Context and Context.CaptureInto or nil)

            if (CaptureInto) then
                CaptureInto[Context.CaptureValue] = Result
                Context.CaptureInto = nil
            end

            local Length = SizeDeserialize(Buffer, Context)

            for Index = 1, Length do
                Result[KeyDeserialize(Buffer, Context)] = ValueDeserialize(Buffer, Context)
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

return Indexable