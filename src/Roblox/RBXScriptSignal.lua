--!native
--!optimize 2

if (not script and Instance) then
    script = game:GetService("ReplicatedFirst").TypeGuard.Roblox.RBXScriptSignal
end

local Template = require(script.Parent.Parent._Template)
    type TypeCheckerConstructor<T, P...> = Template.TypeCheckerConstructor<T, P...>
    type FunctionalArg<T> = Template.FunctionalArg<T>
    type TypeChecker<ExtensionClass, Primitive> = Template.TypeChecker<ExtensionClass, Primitive>

type RBXScriptSignalTypeChecker = TypeChecker<RBXScriptSignalTypeChecker, RBXScriptSignal> & {

};

local Core = script.Parent.Parent.Core
    local Indexable = require(Core.Indexable)

local Checker = Indexable()

Checker = Checker:Modify({
    Name = "RBXScriptSignal";
    _TypeOf = {"RBXScriptSignal"};
})

table.freeze(Checker)

return function()
    return Checker
end :: TypeCheckerConstructor<RBXScriptSignalTypeChecker>