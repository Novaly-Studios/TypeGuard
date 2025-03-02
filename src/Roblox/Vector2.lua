--!native
--!optimize 2

if (not script) then
    script = game:GetService("ReplicatedFirst").TypeGuard.Roblox.Vector2
end

local Template = require(script.Parent.Parent._Template)
    type TypeCheckerConstructor<T, P...> = Template.TypeCheckerConstructor<T, P...>
    type FunctionalArg<T> = Template.FunctionalArg<T>
    type TypeChecker<ExtensionClass, Primitive> = Template.TypeChecker<ExtensionClass, Primitive>
    type SelfReturn<T, P...> = Template.SelfReturn<T, P...>

type Vector2TypeChecker = TypeChecker<Vector2TypeChecker, Vector2> & {
    Float: SelfReturn<Vector2TypeChecker, FunctionalArg<number>>;
    Int: SelfReturn<Vector2TypeChecker, FunctionalArg<number>, FunctionalArg<boolean>>;
};

local Core = script.Parent.Parent.Core
    local Number = require(Core.Number)
        local Float32 = Number():Float(32)
    local Object = require(Core.Object)

local function Vector2Float(self, Precision)
    local Float = Number():Float(Precision)

    return self:_MapCheckers("Number", function(Checker)
        return Float
    end)
end

local function Vector2Int(self, Bits, Unsigned)
    local Int = Number():Integer(Bits, Unsigned)

    return self:_MapCheckers("Number", function(Checker)
        return Int
    end)
end

local Checker = Object({
    X = Float32;
    Y = Float32;
}):Unmap(function(Value)
    return Vector2.new(Value.X, Value.Y)
end):Strict():NoConstraints()
Checker.Float = Vector2Float
Checker.Int = Vector2Int
Checker.Type = "Vector2"
Checker._TypeOf = {Checker.Type}

return function()
    return Checker
end :: TypeCheckerConstructor<Vector2TypeChecker>