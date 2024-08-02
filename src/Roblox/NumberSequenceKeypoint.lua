--!native
--!optimize 2

if (not script) then
    script = game:GetService("ReplicatedFirst").TypeGuard.Roblox.NumberSequenceKeypoint
end

local Template = require(script.Parent.Parent:WaitForChild("_Template"))
    type TypeCheckerConstructor<T, P...> = Template.TypeCheckerConstructor<T, P...>
    type TypeChecker<ExtensionClass, Primitive> = Template.TypeChecker<ExtensionClass, Primitive>
    type SelfReturn<T, P...> = Template.SelfReturn<T, P...>

type NumberSequenceKeypointTypeChecker = TypeChecker<NumberSequenceKeypointTypeChecker, NumberSequenceKeypoint> & {
    
};

local Core = script.Parent.Parent.Core
    local Number = require(Core.Number)
        local Float32 = Number():Float(32)
    local Object = require(Core.Object)
    local Nil = require(Core.Nil)
        local DefaultNil = Nil()
    local Or = require(Core.Or)

local function NumberSequenceKeypointFloat(self, Precision)
    local Float = Number():Float(Precision)
    return self:_MapCheckers("Number", function(Checker)
        return Float
    end)
end

local function NumberSequenceKeypointInt(self, Precision, Signed)
    local Int = Number():Integer(Precision, Signed)
    return self:_MapCheckers("Number", function(Checker)
        return Int
    end)
end

local Checker = Object({
    Envelope = Or(Float32, DefaultNil);
    Value = Float32;
    Time = Float32:RangeInclusive(0, 1);
}):Unmap(function(Value)
    return NumberSequenceKeypoint.new(Value.Time, Value.Value, Value.Envelope)
end):Strict():NoConstraints()
Checker.Float = NumberSequenceKeypointFloat
Checker.Int = NumberSequenceKeypointInt
Checker.Type = "NumberSequenceKeypoint"
Checker._TypeOf = {Checker.Type}

return function()
    return Checker
end :: TypeCheckerConstructor<NumberSequenceKeypointTypeChecker>