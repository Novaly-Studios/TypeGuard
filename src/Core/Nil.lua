--!native
--!optimize 2

if (not script and Instance) then
    script = game:GetService("ReplicatedFirst").TypeGuard.Core.Nil
end

local Template = require(script.Parent.Parent._Template)
    type TypeCheckerConstructor<T, P...> = Template.TypeCheckerConstructor<T, P...>
    type TypeChecker<ExtensionClass, Primitive> = Template.TypeChecker<ExtensionClass, Primitive>

local Util = require(script.Parent.Parent.Util)
    local CreateStandardInitial = Util.CreateStandardInitial

type NilTypeChecker = TypeChecker<NilTypeChecker, nil> & {

};

local NilChecker: (() -> (NilTypeChecker)), NilCheckerClass = Template.Create("Nil")
NilCheckerClass._CacheConstruction = true
NilCheckerClass._Initial = CreateStandardInitial("nil")
NilCheckerClass._TypeOf = {"nil"}

function NilCheckerClass:_UpdateSerialize()
    return {
        _Serialize = function(Buffer, _, _)
            local BufferContext = Buffer.Context
            BufferContext("Nil")
            BufferContext()
        end;
        _Deserialize = function(_, _)
            return nil
        end;
    }
end

return NilChecker