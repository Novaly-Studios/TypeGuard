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
    local Cacheable = require(Core.Cacheable)
    local Object = require(Core.Object)
    local Array = require(Core.Array)
    local Nil = require(Core.Nil)
    local Or = require(Core.Or)

local AllowFunctions = {"Check", "Assert", "AsPredicate", "AsAssert", "Serialize", "Deserialize", "GetConstraint", "_Serialize", "_Deserialize", "_Check", "_Initial", "_UpdateSerializeFunctionCache", "_GetTypeIndexFromValue", "_InitSerialize", "_InitDeserialize", "_InitCheck"}

local function CreateConstructor(Types: {SignatureTypeChecker}, CustomGetType: ((any, any) -> (number?)), AnyID: string)
    ExpectType(CustomGetType, Expect.FUNCTION, 1)

    local AnyToString = `{AnyID}()`

    local DefaultObjectIndex
    local DefaultArrayIndex
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

        if (ValueType == "table" or ValueType == "SharedTable") then
            if (Value[1] == nil) then
                return DefaultObjectIndex
            end

            return DefaultArrayIndex
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

    local function Create(MetatablesSerializer: Or.OrTypeChecker?, IncludeNil: boolean?, TypeMapper: ((SignatureTypeChecker) -> (SignatureTypeChecker))?)
        local Any
        local DidSetup = false

        -- Self-reference / recursive (object or array of type Any). Can't copy the root table.
        local function Setup()
            if (DidSetup) then
                return
            end

            DidSetup = true

            local DefaultObject = Object():OfKeyType(Any):OfValueType(Any)
            local DefaultArray = Array(Any)
            local DefaultNil

            if (MetatablesSerializer) then
                DefaultObject = DefaultObject:CheckMetatable(MetatablesSerializer)
            end

            DefaultObject = Cacheable(DefaultObject)
            DefaultArray = Cacheable(DefaultArray)

            if (IncludeNil) then
                DefaultNil = Nil()
            end

            local _, Index = Any:GetConstraint("IsATypeIn")
            Any._ActiveConstraints = MergeDeep(Any._ActiveConstraints, {
                [Index] = {
                    Args = {
                        [1] = function(ExistingArgs)
                            return ArrayMerge(ExistingArgs, {DefaultArray, DefaultObject, DefaultNil})
                        end;
                    };
                };
            }, true)

            local IsATypeIn = Any._ActiveConstraints[Index].Args[1]
            DefaultObjectIndex = table.find(IsATypeIn, DefaultObject)
            DefaultArrayIndex = table.find(IsATypeIn, DefaultArray)
            DefaultNilIndex = (IncludeNil and table.find(IsATypeIn, DefaultNil) or nil)
            Any:_UpdateSerializeFunctionCache()

            table.freeze(Any)
        end

        local Temp = Or(unpack(Types)):DefineGetType(GetType)
        Temp = (TypeMapper and Temp:RemapDeep(TypeMapper) or Temp)
        Any = table.clone(Temp)

        local AnyDeserialize = Any._Deserialize
        local AnySerialize = Any._Serialize
        local AnyCheck = Any._Check

        Any._Serialize = function(Buffer, Value, Context)
            local BufferContext = Buffer.Context
            BufferContext(AnyID)
            Context = Context or {}
            Setup()

            if (Context.UseAny == Any) then
                AnySerialize(Buffer, Value, Context)
                BufferContext()
                return
            end

            AnySerialize(Buffer, Value, Merge(Context, {
                AnySerialize = AnySerialize;
                UseAny = Any;
            }))
            BufferContext()

            return
        end

        Any._Deserialize = function(Buffer, Context)
            Context = Context or {}
            Setup()

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
            Deserialize: ((self: any, Buffer: buffer, Atom: ("Bit" | "Byte" | "Human")?, BypassCheck: boolean?, Context: any?) -> (any));
            AsPredicate: ((self: any) -> ((Value: any) -> (boolean)));
            Serialize: ((self: any, Value: any, Atom: ("Bit" | "Byte" | "Human")?, BypassCheck: boolean?, Context: any?) -> (buffer));
            AsAssert: ((self: any) -> ((Value: any) -> ()));
            Assert: ((self: any, Value: any) -> ());
            Check: ((self: any, Value: any) -> (boolean));
        }
    end

    return Create
end

return CreateConstructor