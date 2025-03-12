--!native
--!optimize 2

if (not script) then
    script = game:GetService("ReplicatedFirst").TypeGuard.Roblox.RBXScriptConnection
end

local Template = require(script.Parent.Parent._Template)
    type TypeCheckerConstructor<T, P...> = Template.TypeCheckerConstructor<T, P...>
    type FunctionalArg<T> = Template.FunctionalArg<T>
    type TypeChecker<ExtensionClass, Primitive> = Template.TypeChecker<ExtensionClass, Primitive>

type RBXScriptConnectionTypeChecker = TypeChecker<RBXScriptConnectionTypeChecker, RBXScriptConnection> & {

};

local Core = script.Parent.Parent.Core
    local Object = require(Core.Object)

local Checker = Object()
--[[ Checker.Type = "RBXScriptConnection"
Checker._TypeOf = {Checker.Type} ]]

Checker = Checker:Modify({
    Type = "RBXScriptConnection";
    _TypeOf = {"RBXScriptConnection"};
})

return function()
    return Checker
end :: TypeCheckerConstructor<RBXScriptConnectionTypeChecker>