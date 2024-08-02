--!native
--!optimize 2

if (not script) then
    script = game:GetService("ReplicatedFirst").TypeGuard.Roblox.UDim2
end

local Template = require(script.Parent.Parent:WaitForChild("_Template"))
    type TypeCheckerConstructor<T, P...> = Template.TypeCheckerConstructor<T, P...>
    type TypeChecker<ExtensionClass, Primitive> = Template.TypeChecker<ExtensionClass, Primitive>
    type SelfReturn<T, P...> = Template.SelfReturn<T, P...>

type UDim2TypeChecker = TypeChecker<UDim2TypeChecker, UDim2> & {

};

local Core = script.Parent.Parent.Core
    local Object = require(Core.Object)

local UDim = require(script.Parent.UDim)
    local DefaultUDim = UDim()

local Checker = Object({
    X = DefaultUDim;
    Y = DefaultUDim;
}):Unmap(function(Value)
    return UDim2.new(Value.X, Value.Y)
end):Strict():NoConstraints()
Checker.Type = "UDim2"
Checker._TypeOf = {Checker.Type}

return function()
    return Checker
end :: TypeCheckerConstructor<UDim2TypeChecker>