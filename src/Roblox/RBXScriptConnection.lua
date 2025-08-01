--!native
--!optimize 2

if (not script and Instance) then
    script = game:GetService("ReplicatedFirst").TypeGuard.Roblox.RBXScriptConnection
end

local Template = require(script.Parent.Parent._Template)
    type TypeCheckerConstructor<T, P...> = Template.TypeCheckerConstructor<T, P...>
    type FunctionalArg<T> = Template.FunctionalArg<T>
    type TypeChecker<ExtensionClass, Primitive> = Template.TypeChecker<ExtensionClass, Primitive>

type RBXScriptConnectionTypeChecker = TypeChecker<RBXScriptConnectionTypeChecker, RBXScriptConnection> & {

};

local Core = script.Parent.Parent.Core
    local Indexable = require(Core.Indexable)

local Checker = Indexable()

Checker = Checker:Modify({
    Name = "RBXScriptConnection";
    _TypeOf = {"RBXScriptConnection"};
})

table.freeze(Checker)

return function()
    return Checker
end :: TypeCheckerConstructor<RBXScriptConnectionTypeChecker>