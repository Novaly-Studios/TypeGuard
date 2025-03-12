--!native
--!optimize 2

if (not script) then
    script = game:GetService("ReplicatedFirst").TypeGuard.Roblox.NumberSequenceKeypoint
end

local Template = require(script.Parent.Parent._Template)
    type TypeCheckerConstructor<T, P...> = Template.TypeCheckerConstructor<T, P...>
    type TypeChecker<ExtensionClass, Primitive> = Template.TypeChecker<ExtensionClass, Primitive>

type NumberSequenceKeypointTypeChecker = TypeChecker<NumberSequenceKeypointTypeChecker, NumberSequenceKeypoint> & {
    
};

local Core = script.Parent.Parent.Core
    local Number = require(Core.Number)
        local Float32 = Number():Float(32)
    local Object = require(Core.Object)
    local Nil = require(Core.Nil)
        local DefaultNil = Nil()
    local Or = require(Core.Or)

local Checker = Object({
    Envelope = Or(Float32, DefaultNil);
    Value = Float32;
    Time = Float32:RangeInclusive(0, 1);
}):Unmap(function(Value)
    return NumberSequenceKeypoint.new(Value.Time, Value.Value, Value.Envelope)
end):Strict():NoConstraints()
--[[ Checker.Type = "NumberSequenceKeypoint"
Checker._TypeOf = {Checker.Type} ]]

Checker = Checker:Modify({
    Type = "NumberSequenceKeypoint";
    _TypeOf = {"NumberSequenceKeypoint"};
})

return function()
    return Checker
end :: TypeCheckerConstructor<NumberSequenceKeypointTypeChecker>