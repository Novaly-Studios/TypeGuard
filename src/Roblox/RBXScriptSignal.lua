--!native
--!optimize 2

if (not script) then
    script = game:GetService("ReplicatedFirst").TypeGuard.Roblox.RBXScriptSignal
end

local Template = require(script.Parent.Parent._Template)
    type TypeCheckerConstructor<T, P...> = Template.TypeCheckerConstructor<T, P...>
    type FunctionalArg<T> = Template.FunctionalArg<T>
    type TypeChecker<ExtensionClass, Primitive> = Template.TypeChecker<ExtensionClass, Primitive>

type RBXScriptSignalTypeChecker = TypeChecker<RBXScriptSignalTypeChecker, RBXScriptSignal> & {

};

local Core = script.Parent.Parent.Core
    local Object = require(Core.Object)

local Checker = Object()
--[[ Checker.Type = "RBXScriptSignal"
Checker._TypeOf = {Checker.Type} ]]

Checker = Checker:Modify({
    Type = "RBXScriptSignal";
    _TypeOf = {"RBXScriptSignal"};
})

return function()
    return Checker
end :: TypeCheckerConstructor<RBXScriptSignalTypeChecker>