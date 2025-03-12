--!native
--!optimize 2

if (not script) then
    script = game:GetService("ReplicatedFirst").TypeGuard.Roblox.ColorSequenceKeypoint
end

local Template = require(script.Parent.Parent._Template)
    type TypeCheckerConstructor<T, P...> = Template.TypeCheckerConstructor<T, P...>
    type TypeChecker<ExtensionClass, Primitive> = Template.TypeChecker<ExtensionClass, Primitive>

type ColorSequenceKeypointTypeChecker = TypeChecker<ColorSequenceKeypointTypeChecker, ColorSequenceKeypoint> & {
    
};

local Core = script.Parent.Parent.Core
    local Number = require(Core.Number)
        local Float32 = Number():Float(32)
    local Object = require(Core.Object)

local DefaultColor3 = require(script.Parent.Color3)()

local Checker = Object({
    Value = DefaultColor3;
    Time = Float32:RangeInclusive(0, 1);
}):Unmap(function(Value)
    return ColorSequenceKeypoint.new(Value.Time, Value.Value)
end):Strict():NoConstraints()

--[[ Checker.Type = "ColorSequenceKeypoint"
Checker._TypeOf = {Checker.Type} ]]

Checker = Checker:Modify({
    Type = "ColorSequenceKeypoint";
    _TypeOf = {"ColorSequenceKeypoint"};
})

return function()
    return Checker
end :: TypeCheckerConstructor<ColorSequenceKeypointTypeChecker>