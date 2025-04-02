--!native
--!optimize 2

if (not script and Instance) then
    script = game:GetService("ReplicatedFirst").TypeGuard.Core.Boolean
end

local Template = require(script.Parent.Parent._Template)
    type TypeCheckerConstructor<T, P...> = Template.TypeCheckerConstructor<T, P...>
    type TypeChecker<ExtensionClass, Primitive> = Template.TypeChecker<ExtensionClass, Primitive>

local Util = require(script.Parent.Parent.Util)
    local CreateStandardInitial = Util.CreateStandardInitial

type BooleanTypeChecker = TypeChecker<BooleanTypeChecker, boolean> & {

};

local Boolean: ((Value: boolean?) -> (BooleanTypeChecker)), BooleanClass = Template.Create("Boolean")
BooleanClass._CacheConstruction = true
BooleanClass._Initial = CreateStandardInitial("boolean")
BooleanClass._TypeOf = {"boolean"}

function BooleanClass:_UpdateSerialize()
    return {
        _Serialize = function(Buffer, Value, _Context)
            local BufferContext = Buffer.Context
            BufferContext("Boolean")
            Buffer.WriteUInt(1, Value and 1 or 0)
            BufferContext()
        end;
        _Deserialize = function(Buffer, _Context)
            return (Buffer.ReadUInt(1) == 1)
        end;
    }
end

BooleanClass.InitialConstraint = BooleanClass.Equals

return Boolean