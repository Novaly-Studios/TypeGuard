--!native
--!optimize 2

if (not script and Instance) then
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
    local Indexable = require(Core.Indexable)

local DefaultColor3 = require(script.Parent.Color3)()

local Checker = Indexable({
    Value = DefaultColor3;
    Time = Float32:RangeInclusive(0, 1);
}):Unmap(function(Value)
    return ColorSequenceKeypoint.new(Value.Time, Value.Value)
end):Strict():NoConstraints()

Checker = Checker:Modify({
    Name = "ColorSequenceKeypoint";
    _TypeOf = {"ColorSequenceKeypoint"};
})

table.freeze(Checker)

return function()
    return Checker
end :: TypeCheckerConstructor<ColorSequenceKeypointTypeChecker>