--!native
--!optimize 2

if (not script) then
    script = game:GetService("ReplicatedFirst").TypeGuard.Core.ValueCache
end

local Template = require(script.Parent.Parent._Template)
    type TypeCheckerConstructor<T, P...> = Template.TypeCheckerConstructor<T, P...>
    type SignatureTypeChecker = Template.SignatureTypeChecker
    type TypeChecker<ExtensionClass, Primitive> = Template.TypeChecker<ExtensionClass, Primitive>
    type FunctionalArg<T> = Template.FunctionalArg<T>
    type SelfReturn<T, P...> = Template.SelfReturn<T, P...>

local Util = require(script.Parent.Parent.Util)
    local CreateStandardInitial = Util.CreateStandardInitial

local String = require(script.Parent.String)
local Object = require(script.Parent.Object)
local Number = require(script.Parent.Number)
local Or = require(script.Parent.Or)

type ValueCacheTypeChecker = TypeChecker<ValueCacheTypeChecker, nil> & {
    Using: ((self: ValueCacheTypeChecker, Serializer: FunctionalArg<SignatureTypeChecker>) -> (ValueCacheTypeChecker));
};

--- This is used to quickly cache hashable values which might occur more than one time during serialization and deserialization
--- like commonly re-used strings for field names.
--- This doesn't work for BitSerializer yet & need to find out why.
local ValueCache: (() -> (ValueCacheTypeChecker)), ValueCacheCheckerClass = Template.Create("ValueCache")
ValueCacheCheckerClass._Initial = CreateStandardInitial("ValueCache")
ValueCacheCheckerClass.InitialConstraint = ValueCacheCheckerClass.Using

function ValueCacheCheckerClass:Using(Serializer)
    return self:Modify({
        _Using = Serializer;
    })
end

function ValueCacheCheckerClass._Initial()
    return true
end

function ValueCacheCheckerClass:_UpdateSerialize()
    local Serializer = self._Using
    if (not Serializer) then
        return
    end

    local UInt = Number():Integer(32)
        local UIntSerialize = UInt._Serialize
        local UIntDeserialize = UInt._Deserialize
    local CacheSerializer = Object():OfKeyType(Or(Number(), String())):OfValueType(UInt)
        local CacheSerializerDeserialize = CacheSerializer._Deserialize
        local CacheSerializerSerialize = CacheSerializer._Serialize
    local SerializerDeserialize = Serializer._Deserialize

    self._Serialize = function(Buffer, Value, _Cache)
        local Items = {}
        local Count = 0

        local function Cache(Value)
            local Index = Items[Value]
            if (Index) then
                return Index
            end

            Index = Count + 1
            Count = Index
            Items[Value] = Index
            return Index
        end

        local SubBuffer = buffer.tostring(Serializer:Serialize(Value, nil, true, Cache))
        local Length = #SubBuffer
        UIntSerialize(Buffer, Length)
        Buffer.WriteString(SubBuffer, Length * 8)
        CacheSerializerSerialize(Buffer, Items)

        --[[ local SubBuffer = buffer.tostring(Serializer:Serialize(Value, nil, true))
        Buffer.WriteString(SubBuffer, Length * 8) ]]
    end
    self._Deserialize = function(Buffer, Cache)
        local CacheSize = UIntDeserialize(Buffer)
        Buffer.SetPosition(32 + CacheSize * 8)

        local ReversedCache = {}
        for Cached, Index in CacheSerializerDeserialize(Buffer) do
            ReversedCache[Index] = Cached
        end
        Buffer.SetPosition(32)

        return SerializerDeserialize(Buffer, ReversedCache)

        --[[ return SerializerDeserialize(Buffer) ]]
    end
end

return ValueCache