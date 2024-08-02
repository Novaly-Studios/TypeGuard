--!native
--!optimize 2

if (not script) then
    script = game:GetService("ReplicatedFirst").TypeGuard.Roblox.NumberSequence
end

local Template = require(script.Parent.Parent:WaitForChild("_Template"))
    type TypeCheckerConstructor<T, P...> = Template.TypeCheckerConstructor<T, P...>
    type TypeChecker<ExtensionClass, Primitive> = Template.TypeChecker<ExtensionClass, Primitive>
    type SelfReturn<T, P...> = Template.SelfReturn<T, P...>

type NumberSequenceTypeChecker = TypeChecker<NumberSequenceTypeChecker, NumberSequence> & {
    
};

local Core = script.Parent.Parent.Core
    local Object = require(Core.Object)
    local Array = require(Core.Array)

local NumberSequenceKeypointChecker = require(script.Parent.NumberSequenceKeypoint)

local Checker = Object({
    Keypoints = Array(NumberSequenceKeypointChecker());
}):Unmap(function(Value)
    --[[ local Keypoints = Value.Keypoints
    local Result = table.create(#Keypoints)
    for Index, Keypoint in Keypoints do
        Result[Index] = NumberSequenceKeypoint.new(Keypoint.Time, Keypoint.Value)
    end ]]
    return NumberSequence.new(Value.Keypoints)
end):Strict():NoConstraints()
Checker.Type = "NumberSequence"
Checker._TypeOf = {Checker.Type}

return function()
    return Checker
end :: TypeCheckerConstructor<NumberSequenceTypeChecker>