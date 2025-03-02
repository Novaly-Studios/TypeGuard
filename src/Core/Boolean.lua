--!native
--!optimize 2

if (not script) then
    script = game:GetService("ReplicatedFirst").TypeGuard.Core.Boolean
end

local Template = require(script.Parent.Parent._Template)
    type TypeCheckerConstructor<T, P...> = Template.TypeCheckerConstructor<T, P...>
    type TypeChecker<ExtensionClass, Primitive> = Template.TypeChecker<ExtensionClass, Primitive>
    type SelfReturn<T, P...> = Template.SelfReturn<T, P...>

local Util = require(script.Parent.Parent.Util)
    local CreateStandardInitial = Util.CreateStandardInitial

type BooleanTypeChecker = TypeChecker<BooleanTypeChecker, boolean> & {

};

local Boolean: ((Value: boolean?) -> (BooleanTypeChecker)), BooleanClass = Template.Create("Boolean")
BooleanClass._Initial = CreateStandardInitial("boolean")
BooleanClass._TypeOf = {"boolean"}

function BooleanClass:_UpdateSerialize()
    return {
        _Serialize = function(Buffer, Value, _Cache)
            Buffer.WriteUInt(1, Value and 1 or 0)
        end;
        _Deserialize = function(Buffer, _Cache)
            return (Buffer.ReadUInt(1) == 1)
        end;
    }
end

BooleanClass.InitialConstraint = BooleanClass.Equals

return Boolean