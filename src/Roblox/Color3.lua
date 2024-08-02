--!native
--!optimize 2

if (not script) then
    script = game:GetService("ReplicatedFirst").TypeGuard.Roblox.Color3
end

local Template = require(script.Parent.Parent:WaitForChild("_Template"))
    type TypeCheckerConstructor<T, P...> = Template.TypeCheckerConstructor<T, P...>
    type FunctionalArg<T> = Template.FunctionalArg<T>
    type TypeChecker<ExtensionClass, Primitive> = Template.TypeChecker<ExtensionClass, Primitive>
    type SelfReturn<T, P...> = Template.SelfReturn<T, P...>

type Color3TypeChecker = TypeChecker<Color3TypeChecker, Color3> & {
    Float: SelfReturn<Color3TypeChecker, FunctionalArg<number>>;
    Int: SelfReturn<Color3TypeChecker, FunctionalArg<number>>;
};

local Core = script.Parent.Parent.Core
    local Number = require(Core.Number)
        local StandardRange = Number(0, 1)
    local Object = require(Core.Object)

local function Color3Float(self, Precision)
    local Float = Number():Float(Precision)
    return self:_MapCheckers(function(Checker)
        if (Checker.Type ~= "Number") then
            return nil
        end
        return Float
    end)
end

local Checker = Object({
    R = StandardRange;
    G = StandardRange;
    B = StandardRange;
}):Unmap(function(Value)
    return Color3.new(Value.R, Value.G, Value.B)
end):Strict():NoConstraints()
Checker.Float = Color3Float
Checker.Type = "Color3"
Checker._TypeOf = {Checker.Type}

return function()
    return Checker
end :: TypeCheckerConstructor<Color3TypeChecker>