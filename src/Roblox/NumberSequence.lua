--!native
--!optimize 2

if (not script and Instance) then
    script = game:GetService("ReplicatedFirst").TypeGuard.Roblox.NumberSequence
end

local Template = require(script.Parent.Parent._Template)
    type TypeCheckerConstructor<T, P...> = Template.TypeCheckerConstructor<T, P...>
    type TypeChecker<ExtensionClass, Primitive> = Template.TypeChecker<ExtensionClass, Primitive>

type NumberSequenceTypeChecker = TypeChecker<NumberSequenceTypeChecker, NumberSequence> & {
    
};

local Core = script.Parent.Parent.Core
    local Indexable = require(Core.Indexable)
    local Array = require(Core.Array)

local NumberSequenceKeypointChecker = require(script.Parent.NumberSequenceKeypoint)

local Checker = Indexable({
    Keypoints = Array(NumberSequenceKeypointChecker());
}):Unmap(function(Value)
    return NumberSequence.new(Value.Keypoints)
end):Strict():NoConstraints()

Checker = Checker:Modify({
    Name = "NumberSequence";
    _TypeOf = {"NumberSequence"};
})

table.freeze(Checker)

return function()
    return Checker
end :: TypeCheckerConstructor<NumberSequenceTypeChecker>