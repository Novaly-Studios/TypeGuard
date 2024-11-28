--!native
--!optimize 2

if (not script) then
    script = game:GetService("ReplicatedFirst").TypeGuard.Roblox.ColorSequence
end

local Template = require(script.Parent.Parent._Template)
    type TypeCheckerConstructor<T, P...> = Template.TypeCheckerConstructor<T, P...>
    type TypeChecker<ExtensionClass, Primitive> = Template.TypeChecker<ExtensionClass, Primitive>
    type SelfReturn<T, P...> = Template.SelfReturn<T, P...>

type ColorSequenceTypeChecker = TypeChecker<ColorSequenceTypeChecker, ColorSequence> & {
    
};

local Core = script.Parent.Parent.Core
    local Object = require(Core.Object)
    local Array = require(Core.Array)

local ColorSequenceKeypointChecker = require(script.Parent.ColorSequenceKeypoint)

local Checker = Object({
    Keypoints = Array(ColorSequenceKeypointChecker());
}):Unmap(function(Value)
    local Keypoints = Value.Keypoints
    local Result = table.create(#Keypoints)

    for Index, Keypoint in Keypoints do
        Result[Index] = ColorSequenceKeypoint.new(Keypoint.Time, Keypoint.Value)
    end

    return ColorSequence.new(Result)
end):Strict():NoConstraints()
Checker.Type = "ColorSequence"
Checker._TypeOf = {Checker.Type}

return function()
    return Checker
end :: TypeCheckerConstructor<ColorSequenceTypeChecker>