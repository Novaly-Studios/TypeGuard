--!native
--!optimize 2

if (not script) then
    script = game:GetService("ReplicatedFirst").TypeGuard.Core.ValueCache
end

local Template = require(script.Parent.Parent:WaitForChild("_Template"))
    type TypeCheckerConstructor<T, P...> = Template.TypeCheckerConstructor<T, P...>
    type SignatureTypeChecker = Template.SignatureTypeChecker
    type TypeChecker<ExtensionClass, Primitive> = Template.TypeChecker<ExtensionClass, Primitive>
    type FunctionalArg<T> = Template.FunctionalArg<T>
    type SelfReturn<T, P...> = Template.SelfReturn<T, P...>

local Util = require(script.Parent.Parent:WaitForChild("Util"))
    local CreateStandardInitial = Util.CreateStandardInitial

local String = require(script.Parent.String)
local Object = require(script.Parent.Object)
local Number = require(script.Parent.Number)
local Or = require(script.Parent.Or)

type ValueCacheTypeChecker = TypeChecker<ValueCacheTypeChecker, nil> & {
    Using: ((self: ValueCacheTypeChecker, Serializer: FunctionalArg<SignatureTypeChecker>) -> (ValueCacheTypeChecker));
};

local ValueCacheChecker: (() -> (ValueCacheTypeChecker)), ValueCacheCheckerClass = Template.Create("ValueCache")
ValueCacheCheckerClass._Initial = CreateStandardInitial("ValueCache")
ValueCacheCheckerClass.InitialConstraint = ValueCacheCheckerClass.Using

function ValueCacheCheckerClass:Using(Serializer)
    self = self:Copy()
    self._Using = Serializer
    self:_Changed()
    return self
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
            if (not Index) then
                Count += 1
                Index = Count
                Items[Value] = Index
            end
            return Index
        end
        local SubBuffer = buffer.tostring(Serializer:Serialize(Value, nil, true, Cache))
        UIntSerialize(Buffer, #SubBuffer)
        Buffer.WriteString(SubBuffer)
        CacheSerializerSerialize(Buffer, Items)
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
    end
end

return ValueCacheChecker