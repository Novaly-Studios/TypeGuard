--!native
--!optimize 2

if (not script) then
    script = game:GetService("ReplicatedFirst").TypeGuard.Roblox.NumberRange
end

local Template = require(script.Parent.Parent._Template)
    type TypeCheckerConstructor<T, P...> = Template.TypeCheckerConstructor<T, P...>
    type FunctionalArg<T> = Template.FunctionalArg<T>
    type TypeChecker<ExtensionClass, Primitive> = Template.TypeChecker<ExtensionClass, Primitive>
    type SelfReturn<T, P...> = Template.SelfReturn<T, P...>

type NumberRangeTypeChecker = TypeChecker<NumberRangeTypeChecker, NumberRange> & {};

local Core = script.Parent.Parent.Core
    local Number = require(Core.Number)
        local Float32 = Number():Float(32)
    local Object = require(Core.Object)

local Checker = Object({
    Min = Float32;
    Max = Float32;
}):Unmap(function(Value)
    return NumberRange.new(Value.Min, Value.Max)
end):Strict():NoConstraints()
Checker.Type = "NumberRange"
Checker._TypeOf = {Checker.Type}

return function()
    return Checker
end :: TypeCheckerConstructor<NumberRangeTypeChecker>