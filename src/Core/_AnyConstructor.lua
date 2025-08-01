--!native
--!optimize 2

if (not script and Instance) then
    script = game:GetService("ReplicatedFirst").TypeGuard.Roblox.Any
end

local Root = script.Parent.Parent

local Util = require(Root.Util)
    local ExpectType = Util.ExpectType
    local Expect = Util.Expect

local Template = require(Root._Template)
    type SignatureTypeChecker = Template.SignatureTypeChecker

local TableUtil = require(Root.Parent.TableUtil).WithFeatures()
    local ArrayMerge = TableUtil.Array.Merge
    local MergeDeep = TableUtil.Map.MergeDeep
    local Merge = TableUtil.Map.Merge

local Core = Root.Core
    local Indexable = require(Core.Indexable)
    local Cacheable = require(Core.Cacheable)
    local Array = require(Core.Array)
    local Nil = require(Core.Nil)
    local Or = require(Core.Or)

local AllowFunctions = {"Check", "Assert", "AsPredicate", "AsAssert", "Serialize", "Deserialize", "GetConstraint", "_Serialize", "_Deserialize", "_Check", "_Initial", "_UpdateSerializeFunctionCache", "_GetTypeIndexFromValue", "_InitSerialize", "_InitDeserialize", "_InitCheck"}

local function CreateConstructor(Types: {SignatureTypeChecker}, CustomGetType: ((any, any) -> (number?)), AnyID: string)
    ExpectType(CustomGetType, Expect.FUNCTION, 1)

    local AnyToString = `{AnyID}()`

    local DefaultPureMapIndex
    local DefaultPureArrayIndex
    local DefaultMixedIndex
    local DefaultNilIndex = -1
    local TypeToIndex = {}

    for Index, Type in Types do
        for _, TypeOf in Type._TypeOf do
            TypeToIndex[TypeOf] = Index
        end
    end

    local function GetType(Value)
        local ValueType = typeof(Value)
        local CustomIndex = CustomGetType(Value, ValueType)

        if (CustomIndex) then
            return CustomIndex
        end

        if (ValueType == "table") then
            local Size = #Value

            if (Size == 0) then
                -- Size = 0 -> has no array component, write as map.
                return DefaultPureMapIndex
            end

            if (next(Value, Size) == nil) then
                -- Size =/= 0 and next value after Size is nil -> has array component, write as array.
                return DefaultPureArrayIndex
            end

            -- Size =/= 0 and next value after Size is not nil -> has both array and map component, write as mixed.
            return DefaultMixedIndex
        elseif (ValueType == "SharedTable") then
            return DefaultPureMapIndex
        end

        local Index = TypeToIndex[ValueType]

        if (Index) then
            return Index
        end

        if (Value == nil) then
            return DefaultNilIndex
        end

        error(`Unhandled type: {ValueType}`)
    end

    local function Create(MetatablesSerializer: Or.OrTypeChecker?, IncludeNil: boolean?, TypeMapper: ((SignatureTypeChecker) -> (SignatureTypeChecker))?, Step: (() -> ())?)
        local Any
        local DidSetup = false

        -- Self-reference / recursive (object or array of type Any). Can't copy the root table.
        local function Setup()
            if (DidSetup) then
                return
            end

            DidSetup = true

            local DefaultPureArray = Array(Any)
            local DefaultPureMap = Indexable():PureMap(Any, Any)
            local DefaultMixed = Indexable(Any, Any)
            local DefaultNil

            if (MetatablesSerializer) then
                DefaultPureArray = DefaultPureArray:CheckMetatable(MetatablesSerializer)
                DefaultPureMap = DefaultPureMap:CheckMetatable(MetatablesSerializer)
                DefaultMixed = DefaultMixed:CheckMetatable(MetatablesSerializer)
            end

            DefaultPureArray = Cacheable(DefaultPureArray)
            DefaultPureMap = Cacheable(DefaultPureMap)
            DefaultMixed = Cacheable(DefaultMixed)

            if (IncludeNil) then
                DefaultNil = Nil()
            end

            local _, Index = Any:GetConstraint("IsATypeIn")
            local NewActiveConstraints = MergeDeep(Any._ActiveConstraints, {
                [Index] = {
                    Args = {
                        [1] = function(ExistingArgs)
                            return ArrayMerge(ExistingArgs, {DefaultPureArray, DefaultPureMap, DefaultMixed, DefaultNil})
                        end;
                    };
                };
            }, true)
            Any._ActiveConstraints = NewActiveConstraints

            local IsATypeIn = NewActiveConstraints[Index].Args[1]
            DefaultPureArrayIndex = table.find(IsATypeIn, DefaultPureArray)
            DefaultPureMapIndex = table.find(IsATypeIn, DefaultPureMap)
            DefaultMixedIndex = table.find(IsATypeIn, DefaultMixed)
            DefaultNilIndex = (IncludeNil and table.find(IsATypeIn, DefaultNil) or nil)
            Any:_UpdateSerializeFunctionCache()
            table.freeze(Any)

            return
        end

        local Temp = Or(unpack(Types)):DefineGetType(GetType)
        Temp = (TypeMapper and Temp:RemapDeep(TypeMapper) or Temp)
        Any = table.clone(Temp)

        local AnyDeserialize = Any._Deserialize
        local AnySerialize = Any._Serialize
        local AnyCheck = Any._Check

        Any._Serialize = function(Buffer, Value, Context)
            local BufferContext = Buffer.Context

            if (BufferContext) then
                BufferContext(AnyID)
            end

            Context = Context or {}
            Setup()

            if (Step) then
                Step()
            end

            if (Context.UseAny == Any) then
                AnySerialize(Buffer, Value, Context)

                if (BufferContext) then
                    BufferContext()
                end

                return
            end

            AnySerialize(Buffer, Value, Merge(Context, {
                AnySerialize = AnySerialize;
                UseAny = Any;
            }))

            if (BufferContext) then
                BufferContext()
            end

            return
        end

        Any._Deserialize = function(Buffer, Context)
            Context = Context or {}
            Setup()

            if (Step) then
                Step()
            end

            if (Context.UseAny == Any) then
                return AnyDeserialize(Buffer, Context)
            end

            return AnyDeserialize(Buffer, Merge(Context, {
                AnyDeserialize = AnyDeserialize;
                UseAny = Any;
            }))
        end

        Any._Check = function(self, Value)
            Setup()
            return AnyCheck(self, Value)
        end

        -- Avoid recursive tostring weirdness.
        local NewMT = table.clone(getmetatable(Any))
        NewMT.__tostring = function()
            return AnyToString
        end
        setmetatable(Any, NewMT)

        -- Disallow all constraints or functions which would copy the root, as that will break the self-reference to Any.
        for Key, Value in Any do
            if (type(Value) ~= "function") then
                continue
            end

            if (table.find(AllowFunctions, Key)) then
                continue
            end

            Any[Key] = nil
        end

        return Any :: {
            Deserialize: ((self: any, Buffer: buffer, Atom: Util.Serializer?, BypassCheck: boolean?, Context: any?) -> (any));
            AsPredicate: ((self: any) -> ((Value: any) -> (boolean)));
            Serialize: ((self: any, Value: any, Atom: Util.Serializer?, BypassCheck: boolean?, Context: any?) -> (buffer));
            AsAssert: ((self: any) -> ((Value: any) -> ()));
            Assert: ((self: any, Value: any) -> ());
            Check: ((self: any, Value: any) -> (boolean));
        }
    end

    return Create
end

return CreateConstructor