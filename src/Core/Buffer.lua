--!native
--!optimize 2

if (not script and Instance) then
    script = game:GetService("ReplicatedFirst").TypeGuard.Core.Buffer
end

local Template = require(script.Parent.Parent._Template)
    type TypeCheckerConstructor<T, P...> = Template.TypeCheckerConstructor<T, P...>
    type SignatureTypeChecker = Template.SignatureTypeChecker
    type TypeChecker<ExtensionClass, Primitive> = Template.TypeChecker<ExtensionClass, Primitive>

local Util = require(script.Parent.Parent.Util)
    local CreateStandardInitial = Util.CreateStandardInitial

local Number = require(script.Parent.Number)

type BufferTypeChecker = TypeChecker<BufferTypeChecker, buffer> & {
    Aligned: ((self: BufferTypeChecker) -> (BufferTypeChecker));
}

local Buffer: (() -> (BufferTypeChecker)), BufferClass = Template.Create("Buffer")
BufferClass._CacheConstruction = true
BufferClass._Initial = CreateStandardInitial("buffer")
BufferClass._TypeOf = {"buffer"}

local DynamicUInt = Number():Integer(32, false):Positive():Dynamic()
    local DynamicUIntDeserialize = DynamicUInt._Deserialize
    local DynamicUIntSerialize = DynamicUInt._Serialize

--- Ensures the string is aligned to the nearest byte for fast writes (for BitSerializer).
function BufferClass:Aligned()
    return self:Modify({
        _Aligned = true;
    })
end

function BufferClass:_UpdateSerialize()
    local Aligned = self._Aligned

    return {
        _Serialize = function(Buffer, Value, Context)
            local BufferContext = Buffer.Context

            if (BufferContext) then
                BufferContext("Buffer")
            end

            local Length = buffer.len(Value)
            DynamicUIntSerialize(Buffer, Length, Context)

            if (Aligned) then
                Buffer.Align()
            end

            Buffer.WriteBuffer(Value, Length * 8)

            if (BufferContext) then
                BufferContext()
            end
        end;
        _Deserialize = function(Buffer, Context)
            local Length = DynamicUIntDeserialize(Buffer, Context) * 8

            if (Aligned) then
                Buffer.Align()
            end

            return Buffer.ReadBuffer(Length)
        end;
    }
end

return Buffer