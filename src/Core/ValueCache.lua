--!native
--!optimize 2

if (not script and Instance) then
    script = game:GetService("ReplicatedFirst").TypeGuard.Core.ValueCache
end

local Template = require(script.Parent.Parent._Template)
    type SignatureTypeChecker = Template.SignatureTypeChecker
    type TypeChecker<ExtensionClass, Primitive> = Template.TypeChecker<ExtensionClass, Primitive>

local TableUtil = require(script.Parent.Parent.Parent.TableUtil).WithFeatures()
    local Merge = TableUtil.Map.Merge

local Util = require(script.Parent.Parent.Util)
    local CreateStandardInitial = Util.CreateStandardInitial
    local AssertIsTypeBase = Util.AssertIsTypeBase
    local ExpectType = Util.ExpectType
    local Expect = Util.Expect

type ValueCacheTypeChecker = TypeChecker<ValueCacheTypeChecker, nil> & {
    PersistentCache: ((self: ValueCacheTypeChecker, GetIndexFromValue: ((any?) -> (number?)), GetValueFromIndex: ((number) -> (any))) -> (ValueCacheTypeChecker));
    Using: ((self: ValueCacheTypeChecker, Serializer: SignatureTypeChecker) -> (ValueCacheTypeChecker));
};

--- This is used to quickly cache hashable values which might occur more than one time during serialization and deserialization
--- like commonly re-used strings for field names. Or to cache the first encounter with objects referenced multiple times.
local ValueCache: ((Serializer: SignatureTypeChecker?) -> (ValueCacheTypeChecker)), ValueCacheCheckerClass = Template.Create("ValueCache")
ValueCacheCheckerClass._Initial = CreateStandardInitial("ValueCache")

function ValueCacheCheckerClass:Using(Serializer)
    AssertIsTypeBase(Serializer, 1)

    return self:Modify({
        _Using = Serializer;
    })
end

function ValueCacheCheckerClass:PersistentCache(GetIndexFromValue, GetValueFromIndex)
    ExpectType(GetIndexFromValue, Expect.FUNCTION, 1)
    ExpectType(GetValueFromIndex, Expect.FUNCTION, 2)

    return self:Modify({
        _GetIndexFromValue = function()
            return GetIndexFromValue
        end;
        _GetValueFromIndex = function()
            return GetValueFromIndex
        end;
    })
end

function ValueCacheCheckerClass:GetCaches()
    return self._GetIndexFromValue, self._GetValueFromIndex
end

function ValueCacheCheckerClass:_Initial(Value)
    return self._Using:Check(Value)
end

function ValueCacheCheckerClass:_UpdateSerialize()
    local Serializer = self._Using

    if (not Serializer) then
        return
    end

    local GetIndexFromValue = self._GetIndexFromValue
    local GetValueFromIndex = self._GetValueFromIndex

    local ValueCacheOf = `ValueCache({Serializer.Name})`

    return {
        _Serialize = function(Buffer, Value, Context)
            local BufferContext = Buffer.Context
            BufferContext(ValueCacheOf)

            Serializer._Serialize(Buffer, Value, Merge(Context or {}, {
                GetIndexFromValue = GetIndexFromValue;
                ValueToPosition = (Context and Context.ValueToPosition or {});
            }))

            BufferContext()
        end;
        _Deserialize = function(Buffer, Context)
            return Serializer._Deserialize(Buffer, Merge(Context or {}, {
                GetValueFromIndex = GetValueFromIndex;
                PositionToValue = (Context and Context.PositionToValue or {});
            }))
        end;
    }
end

ValueCacheCheckerClass.InitialConstraint = ValueCacheCheckerClass.Using
return ValueCache