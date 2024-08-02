--!native
--!optimize 2

if (not script) then
    script = game:GetService("ReplicatedFirst").TypeGuard.Roblox.ColorSequenceKeypoint
end

local Template = require(script.Parent.Parent:WaitForChild("_Template"))
    type TypeCheckerConstructor<T, P...> = Template.TypeCheckerConstructor<T, P...>
    type TypeChecker<ExtensionClass, Primitive> = Template.TypeChecker<ExtensionClass, Primitive>
    type SelfReturn<T, P...> = Template.SelfReturn<T, P...>

type ColorSequenceKeypointTypeChecker = TypeChecker<ColorSequenceKeypointTypeChecker, ColorSequenceKeypoint> & {
    
};

local Core = script.Parent.Parent.Core
    local Number = require(Core.Number)
        local Float32 = Number():Float(32)
    local Object = require(Core.Object)

local DefaultColor3 = require(script.Parent.Color3)()

local function ColorSequenceKeypointFloat(self, Precision)
    local Float = Number():Float(Precision)
    return self:_MapCheckers("Number", function(Checker)
        return Float
    end)
end

local function ColorSequenceKeypointInt(self, Precision, Signed)
    local Int = Number():Integer(Precision, Signed)
    return self:_MapCheckers("Number", function(Checker)
        return Int
    end)
end

local Checker = Object({
    Value = DefaultColor3;
    Time = Float32:RangeInclusive(0, 1);
}):Unmap(function(Value)
    return ColorSequenceKeypoint.new(Value.Time, Value.Value)
end):Strict():NoConstraints()
Checker.Float = ColorSequenceKeypointFloat
Checker.Int = ColorSequenceKeypointInt
Checker.Type = "ColorSequenceKeypoint"
Checker._TypeOf = {Checker.Type}

return function()
    return Checker
end :: TypeCheckerConstructor<ColorSequenceKeypointTypeChecker>