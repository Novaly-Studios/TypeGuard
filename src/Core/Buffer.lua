--!native
--!optimize 2

if (not script and Instance) then
    script = game:GetService("ReplicatedFirst").TypeGuard.Core.Buffer
end

local Template = require(script.Parent.Parent._Template)
    type TypeCheckerConstructor<T, P...> = Template.TypeCheckerConstructor<T, P...>
    type TypeChecker<ExtensionClass, Primitive> = Template.TypeChecker<ExtensionClass, Primitive>

local Util = require(script.Parent.Parent.Util)
    local CreateStandardInitial = Util.CreateStandardInitial

local Cacheable = require(script.Parent.Cacheable)
local String = require(script.Parent.String)

type BufferTypeChecker = TypeChecker<BufferTypeChecker, buffer> & {

};

local Buffer: (() -> (BufferTypeChecker)), BufferClass = Template.Create("Buffer")
BufferClass._CacheConstruction = true
BufferClass._Initial = CreateStandardInitial("buffer")
BufferClass._TypeOf = {"buffer"}

function BufferClass:_UpdateSerialize()
    local Serializer = Cacheable(String())
        local Deserialize = Serializer._Deserialize
        local Serialize = Serializer._Serialize

    return {
        _Serialize = function(Buffer, Value, Context)
            local BufferContext = Buffer.Context
            BufferContext("Buffer")
            Serialize(Buffer, buffer.tostring(Value), Context)
            BufferContext()
        end;
        _Deserialize = function(Buffer, Context)
            return buffer.fromstring(Deserialize(Buffer, Context))
        end;
    }
end

return Buffer