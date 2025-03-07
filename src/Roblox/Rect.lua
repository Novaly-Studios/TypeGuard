--!native
--!optimize 2

if (not script) then
    script = game:GetService("ReplicatedFirst").TypeGuard.Roblox.Rect
end

local Template = require(script.Parent.Parent._Template)
    type TypeCheckerConstructor<T, P...> = Template.TypeCheckerConstructor<T, P...>
    type FunctionalArg<T> = Template.FunctionalArg<T>
    type TypeChecker<ExtensionClass, Primitive> = Template.TypeChecker<ExtensionClass, Primitive>
    type SelfReturn<T, P...> = Template.SelfReturn<T, P...>

type RectTypeChecker = TypeChecker<RectTypeChecker, Rect> & {

};

local Core = script.Parent.Parent.Core
    local Object = require(Core.Object)

local Vector2Serializer = require(script.Parent.Vector2)
    local DefaultVector2 = Vector2Serializer()

local Checker = Object({
    Min = DefaultVector2;
    Max = DefaultVector2;
}):Unmap(function(Value)
    return Rect.new(Value.Min, Value.Max)
end):Strict():NoConstraints()
Checker.Type = "Rect"
Checker._TypeOf = {Checker.Type}

return function()
    return Checker
end :: TypeCheckerConstructor<RectTypeChecker>