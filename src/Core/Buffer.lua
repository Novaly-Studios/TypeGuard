--!native
--!optimize 2

if (not script) then
    script = game:GetService("ReplicatedFirst").TypeGuard.Core.Buffer
end

local Template = require(script.Parent.Parent._Template)
    type TypeCheckerConstructor<T, P...> = Template.TypeCheckerConstructor<T, P...>
    type TypeChecker<ExtensionClass, Primitive> = Template.TypeChecker<ExtensionClass, Primitive>

local Util = require(script.Parent.Parent.Util)
    local CreateStandardInitial = Util.CreateStandardInitial

local String = require(script.Parent.String)

type BufferTypeChecker = TypeChecker<BufferTypeChecker, buffer> & {

};

local Buffer: (() -> (BufferTypeChecker)), BufferClass = Template.Create("Buffer")
BufferClass._CacheConstruction = true
BufferClass._Initial = CreateStandardInitial("buffer")
BufferClass._TypeOf = {"buffer"}

function BufferClass:_UpdateSerialize()
    local Serializer = String()
        local Deserialize = Serializer._Deserialize
        local Serialize = Serializer._Serialize

    return {
        _Serialize = function(Buffer, Value, Cache)
            Serialize(Buffer, buffer.tostring(Value), Cache)
        end;
        _Deserialize = function(Buffer, Cache)
            return buffer.fromstring(Deserialize(Buffer, Cache))
        end;
    }
end

return Buffer