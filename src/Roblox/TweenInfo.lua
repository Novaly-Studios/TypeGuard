--!native
--!optimize 2

if (not script) then
    script = game:GetService("ReplicatedFirst").TypeGuard.Roblox.Ray
end

local Template = require(script.Parent.Parent._Template)
    type TypeCheckerConstructor<T, P...> = Template.TypeCheckerConstructor<T, P...>
    type FunctionalArg<T> = Template.FunctionalArg<T>
    type TypeChecker<ExtensionClass, Primitive> = Template.TypeChecker<ExtensionClass, Primitive>

type TweenInfoTypeChecker = TypeChecker<TweenInfoTypeChecker, TweenInfo> & {

};

local Core = script.Parent.Parent.Core
    local Number = require(Core.Number)
        local Float32 = Number():Float(32)
        local UInt32 = Number():Integer(32, true)
    local Boolean = require(Core.Boolean)
        local DefaultBoolean = Boolean()
    local Object = require(Core.Object)

local EnumChecker = require(script.Parent.Enum)

local Checker = Object({
    EasingDirection = EnumChecker(Enum.EasingDirection);
    EasingStyle = EnumChecker(Enum.EasingStyle);
    RepeatCount = UInt32;
    DelayTime = Float32;
    Reverses = DefaultBoolean;
    Time = Float32;
}):Unmap(function(Value)
    return TweenInfo.new(Value.Time, Value.EasingStyle, Value.EasingDirection, Value.RepeatCount, Value.Reverses, Value.DelayTime)
end):Strict():NoConstraints()
--[[ Checker.Type = "TweenInfo"
Checker._TypeOf = {Checker.Type} ]]

Checker = Checker:Modify({
    Type = "TweenInfo";
    _TypeOf = {"TweenInfo"};
})

return function()
    return Checker
end :: TypeCheckerConstructor<TweenInfoTypeChecker>