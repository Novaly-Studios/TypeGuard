--!native
--!nonstrict
--!optimize 2

if (not script) then
    script = game:GetService("ReplicatedFirst").TypeGuard.Core.Object
end

local Template = require(script.Parent.Parent._Template)
    type TypeCheckerConstructor<T, P...> = Template.TypeCheckerConstructor<T, P...>
    type SignatureTypeChecker = Template.SignatureTypeChecker
    type FunctionalArg<T> = Template.FunctionalArg<T>
    type TypeChecker<ExtensionClass, Primitive> = Template.TypeChecker<ExtensionClass, Primitive>
    type SelfReturn<T, P...> = Template.SelfReturn<T, P...>

local Util = require(script.Parent.Parent.Util)
    local AssertIsTypeBase = Util.AssertIsTypeBase
    local ExpectType = Util.ExpectType
    local Expect = Util.Expect

local TableUtil = require(script.Parent.Parent.Parent.TableUtil).WithFeatures()
    local MergeDeep = TableUtil.Map.MergeDeep

local Number = require(script.Parent.Number)

type IndexableTypeChecker = TypeChecker<IndexableTypeChecker, {any}> & {
    ContainsValueOfType: ((self: IndexableTypeChecker, Checker: FunctionalArg<SignatureTypeChecker>) -> (IndexableTypeChecker));
    ContainsKeyOfType: ((self: IndexableTypeChecker, Checker: FunctionalArg<SignatureTypeChecker>) -> (IndexableTypeChecker));
    CheckMetatable: ((self: IndexableTypeChecker, Checker: FunctionalArg<SignatureTypeChecker>) -> (IndexableTypeChecker));
    UnmapStructure: ((self: IndexableTypeChecker, Unmapper: FunctionalArg<(any?) -> (any?)>) -> (IndexableTypeChecker));
    OfStructureFC: ((self: IndexableTypeChecker, Structure: FunctionalArg<{{[any]: SignatureTypeChecker}}>) -> (IndexableTypeChecker));
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

local Indexable: (<Structure>(Structure: Structure?) -> (IndexableTypeChecker)), IndexableClass = Template.Create("Structure")
IndexableClass._TypeOf = {"table"}
IndexableClass.Type = "table"

function IndexableClass:_Initial(TargetStructure)
    local Type = typeof(TargetStructure)

    -- Some structures are userdata & typeof will report their name directly. Serializers will overwrite 'Type' with the name.
    local ExpectedType = self.Type
    if (Type == ExpectedType) then
        return true
    end

    return false, `Expected {ExpectedType}, got {Type}`
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

    return self:_AddConstraint(true, "OfStructure", function(SelfRef, StructureToCheck, SubTypes)
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
    end, SubTypes)
end

--- For all values in the passed table, they must satisfy the TypeChecker passed to this constraint.
function IndexableClass:OfValueType(SubType)
    if (type(SubType) ~= "function") then
        AssertIsTypeBase(SubType, 1)
    end

    return self:_AddConstraint(true, "OfValueType", function(_, TargetArray, SubType)
        local Check = SubType._Check

        for Index, Value in TargetArray do
            local Success, SubMessage = Check(SubType, Value)
            if (not Success) then
                return false, `[OfValueType: Key '{Index}'] {SubMessage}`
            end
        end

        return true
    end, SubType)
end

--- For all keys in the passed table, they must satisfy the TypeChecker passed to this constraint.
function IndexableClass:OfKeyType(SubType)
    if (type(SubType) ~= "function") then
        AssertIsTypeBase(SubType, 1)
    end

    return self:_AddConstraint(true, "OfKeyType", function(_, TargetArray, SubType)
        local Check = SubType._Check

        for Key in TargetArray do
            local Success, SubMessage = Check(SubType, Key)

            if (not Success) then
                return false, `[OfKeyType: Key '{Key}'] {SubMessage}`
            end
        end

        return true
    end, SubType)
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

--- Checks if an object is frozen.
function IndexableClass:IsFrozen()
    return self:_AddConstraint(true, "IsFrozen", function(_, Target)
        if (table.isfrozen(Target)) then
            return true
        end

        return false, "Table was not frozen"
    end)
end

--- Checks an object's metatable.
function IndexableClass:CheckMetatable(Checker)
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
function IndexableClass:OfClass(Class)
    ExpectType(Class, Expect.TABLE, 1)
    assert(Class.__index, "Class must have an __index")

    return self:CheckMetatable(Indexable():Equals(Class))
end

--- Checks if an object contains a value which satisfies the given TypeChecker.
function IndexableClass:ContainsValueOfType(Checker)
    AssertIsTypeBase(Checker, 1)

    return self:_AddConstraint(false, "ContainsValueOfType", function(_, Target, Checker)
        local Check = Checker._Check

        for _, Value in Target do
            local Success = Check(Checker, Value)

            if (Success) then
                return true
            end
        end

        return false, `[ContainsValueOfType] did not contain any values which satisfied {Checker}`
    end, Checker)
end

--- Checks if an object contains a value which satisfies the given TypeChecker.
function IndexableClass:ContainsKeyOfType(Checker)
    AssertIsTypeBase(Checker, 1)

    return self:_AddConstraint(false, "ContainsKeyOfType", function(_, Target, Checker)
        local Check = Checker._Check

        for Key in Target do
            local Success = Check(Checker, Key)

            if (Success) then
                return true
            end
        end

        return false, `[ContainsKeyOfType] did not contain any values which satisfied {Checker}`
    end, Checker)
end

function IndexableClass:MinSize(MinSize)
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

function IndexableClass:MaxSize(MaxSize)
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

local Original = IndexableClass._MapCheckers
function IndexableClass:_MapCheckers(Type, Mapper, Recursive)
    local Copy = Original(self, Type, Mapper, Recursive)
        local MapStructure = Copy._MapStructure

    if (MapStructure and Recursive and MapStructure[1]._MapCheckers) then
        MapStructure[1] = MapStructure[1]:_MapCheckers(Type, Mapper, true)
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

function IndexableClass:_UpdateSerialize()
    local HasFunctionalConstraints = self:_HasFunctionalConstraints()
    local MapStructure = self._MapStructure
    local OfStructure = self:GetConstraint("OfStructure")
    local OfValueType = self:GetConstraint("OfValueType")
    local OfKeyType = self:GetConstraint("OfKeyType")

    if (HasFunctionalConstraints or not (MapStructure or OfStructure or (OfValueType and OfKeyType))) then
        local AnySerialize, AnyDeserialize

        return {
            _Serialize = function(Buffer, Array, Cache)
                if (not AnySerialize) then
                    local Any = require(script.Parent.Parent.Roblox.Any) :: any
                    AnySerialize = Any._Serialize
                    Any:Serialize(1) -- Initialize Any.
                end

                AnySerialize(Buffer, Array, Cache)
            end;

            _Deserialize = function(Buffer, Array, Cache)
                if (not AnyDeserialize) then
                    local Any = require(script.Parent.Parent.Roblox.Any) :: any
                    AnyDeserialize = Any._Deserialize
                    Any:Serialize(1) -- Initialize Any.
                end

                return AnyDeserialize(Buffer, Array, Cache)
            end;
        }
    end

    local OfClass = self:GetConstraint("OfClass")
        local OfClassValue = OfClass and OfClass[1]

    local function ApplyClass(Target)
        if (not OfClassValue) then
            return Target
        end

        return setmetatable(Target, OfClassValue)
    end

    if (OfStructure or MapStructure) then
        local Strict = self._Strict

        if (Strict) then
            local MapStructureFunction = (MapStructure and MapStructure[2] or function(Value)
                return Value
            end)
            local UnmapStructureFunction = (self._Unmap or self._UnmapStructure or function(Value)
                return Value
            end)
            local StructureDefinition = (MapStructure and MapStructure[1] and MapStructure[1]:GetConstraint("OfStructure") and MapStructure[1]:GetConstraint("OfStructure")[1]) or (OfStructure and OfStructure[1])
            local HasSingleType = true
            local CommonType = typeof((next(StructureDefinition)))

            for Key in StructureDefinition do
                HasSingleType = (CommonType == typeof(Key))

                if (not HasSingleType) then
                    break
                end
            end

            local KeyToSerializeFunction = table.clone(StructureDefinition)
            for Key, Value in StructureDefinition do
                KeyToSerializeFunction[Key] = Value._Serialize
            end

            local KeyToDeserializeFunction = table.clone(StructureDefinition)
            for Key, Value in StructureDefinition do
                KeyToDeserializeFunction[Key] = Value._Deserialize
            end

            if (HasSingleType and CommonType == "string") then
                local IndexToKey = {}

                for Key in StructureDefinition do
                    table.insert(IndexToKey, Key)
                end

                table.sort(IndexToKey)

                return {
                    _Serialize = function(Buffer, Value, Cache)
                        Value = MapStructureFunction(Value)

                        for _, Key in IndexToKey do
                            KeyToSerializeFunction[Key](Buffer, Value[Key], Cache)
                        end
                    end;
                    _Deserialize = function(Buffer, Cache)
                        local Result = {}

                        for _, Key in IndexToKey do
                            Result[Key] = KeyToDeserializeFunction[Key](Buffer, Cache)
                        end

                        return ApplyClass(UnmapStructureFunction(Result))
                    end;
                }
            end
        end
    end

    if (not (OfValueType and OfKeyType)) then
        return {}
    end
    
    local OfValueTypeChecker = OfValueType[1]
        local ValueDeserialize = OfValueTypeChecker._Deserialize
        local ValueSerialize = OfValueTypeChecker._Serialize

    local OfKeyTypeChecker = OfKeyType[1]
        local KeyDeserialize = OfKeyTypeChecker._Deserialize
        local KeySerialize = OfKeyTypeChecker._Serialize

    local MaxSize = self:GetConstraint("MaxSize")
    local SizeSerializer = (MaxSize and Number(0, MaxSize[1]):Integer() or Number():Integer():Positive():Dynamic())
        local SizeSerialize = SizeSerializer._Serialize
        local SizeDeserialize = SizeSerializer._Deserialize

    local GroupKV = self._GroupKV

    if (GroupKV) then
        return {
            _Serialize = function(Buffer, Value, Cache)
                local Length = 0

                for _ in Value do
                    Length += 1
                end

                SizeSerialize(Buffer, Length, Cache)

                for Key in Value do
                    KeySerialize(Buffer, Key, Cache)
                end

                for _, Value in Value do
                    ValueSerialize(Buffer, Value, Cache)
                end
            end;
            _Deserialize = function(Buffer, Cache)
                local Size = SizeDeserialize(Buffer, Cache)
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

                return ApplyClass(Result)
            end;
        }
    end

    return {
        _Serialize = function(Buffer, Value, Cache)
            local Length = 0

            for _ in Value do
                Length += 1
            end

            SizeSerialize(Buffer, Length, Cache)

            for Key, Value in Value do
                KeySerialize(Buffer, Key, Cache)
                ValueSerialize(Buffer, Value, Cache)
            end
        end;
        _Deserialize = function(Buffer, Cache)
            local Result = {}
            local Length = SizeDeserialize(Buffer, Cache)

            for Index = 1, Length do
                Result[KeyDeserialize(Buffer, Cache)] = ValueDeserialize(Buffer, Cache)
            end

            return ApplyClass(Result)
        end;
    }
end

IndexableClass.InitialConstraint = IndexableClass.OfStructure

return Indexable