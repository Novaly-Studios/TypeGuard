--!native
--!optimize 2

if (not script) then
    script = game:GetService("ReplicatedFirst").TypeGuard.Roblox.NumberSequence
end

local Template = require(script.Parent.Parent._Template)
    type TypeCheckerConstructor<T, P...> = Template.TypeCheckerConstructor<T, P...>
    type TypeChecker<ExtensionClass, Primitive> = Template.TypeChecker<ExtensionClass, Primitive>

type NumberSequenceTypeChecker = TypeChecker<NumberSequenceTypeChecker, NumberSequence> & {
    
};

local Core = script.Parent.Parent.Core
    local Object = require(Core.Object)
    local Array = require(Core.Array)

local NumberSequenceKeypointChecker = require(script.Parent.NumberSequenceKeypoint)

local Checker = Object({
    Keypoints = Array(NumberSequenceKeypointChecker());
}):Unmap(function(Value)
    return NumberSequence.new(Value.Keypoints)
end):Strict():NoConstraints()
--[[ Checker.Type = "NumberSequence"
Checker._TypeOf = {Checker.Type} ]]

Checker = Checker:Modify({
    Type = "NumberSequence";
    _TypeOf = {"NumberSequence"};
})

return function()
    return Checker
end :: TypeCheckerConstructor<NumberSequenceTypeChecker>