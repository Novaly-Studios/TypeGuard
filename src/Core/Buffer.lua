--!native
--!optimize 2

if (not script) then
    script = game:GetService("ReplicatedFirst").TypeGuard.Core.Buffer
end

local Template = require(script.Parent.Parent:WaitForChild("_Template"))
    type TypeCheckerConstructor<T, P...> = Template.TypeCheckerConstructor<T, P...>
    type TypeChecker<ExtensionClass, Primitive> = Template.TypeChecker<ExtensionClass, Primitive>
    type SelfReturn<T, P...> = Template.SelfReturn<T, P...>

local Util = require(script.Parent.Parent.Util)
    local CreateStandardInitial = Util.CreateStandardInitial

type BufferTypeChecker = TypeChecker<BufferTypeChecker, buffer> & {

};

local Buffer: (() -> (BufferTypeChecker)), BufferClass = Template.Create("Buffer")
BufferClass._Initial = CreateStandardInitial("buffer")
BufferClass._TypeOf = {"buffer"}

function BufferClass:_UpdateSerialize()
    self._Serialize = function(Buffer, Value, _Cache)
        local AsString = buffer.tostring(Value)
        Buffer.WriteUInt(32, #AsString)
        Buffer.WriteString(AsString)
    end
    self._Deserialize = function(Buffer, _Cache)
        return buffer.fromstring(Buffer.ReadString(Buffer.ReadUInt(32) * 8))
    end
end

return Buffer