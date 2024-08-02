--!native
--!optimize 2

if (not script) then
    script = game:GetService("ReplicatedFirst").TypeGuard.Roblox.Vector3
end

local Template = require(script.Parent.Parent:WaitForChild("_Template"))
    type TypeCheckerConstructor<T, P...> = Template.TypeCheckerConstructor<T, P...>
    type FunctionalArg<T> = Template.FunctionalArg<T>
    type TypeChecker<ExtensionClass, Primitive> = Template.TypeChecker<ExtensionClass, Primitive>
    type SelfReturn<T, P...> = Template.SelfReturn<T, P...>

type Vector3TypeChecker = TypeChecker<Vector3TypeChecker, Vector3> & {
    Float: SelfReturn<Vector3TypeChecker, FunctionalArg<number>>;
    Int: SelfReturn<Vector3TypeChecker, FunctionalArg<number>, FunctionalArg<boolean>>;
};

local Core = script.Parent.Parent.Core
    local Number = require(Core.Number)
        local Float32 = Number():Float(32)
    local Object = require(Core.Object)

local function Vector3Float(self, Precision)
    local Float = Number():Float(Precision)
    return self:_MapCheckers("Number", function(Checker)
        return Float
    end)
end

local function Vector3Int(self, Bits, Unsigned)
    local Int = Number():Integer(Bits, Unsigned)
    return self:_MapCheckers("Number", function(Checker)
        return Int
    end)
end

local Checker = Object({
    X = Float32;
    Y = Float32;
    Z = Float32;
}):Unmap(function(Value)
    return Vector3.new(Value.X, Value.Y, Value.Z)
end):Strict():NoConstraints()
Checker.Float = Vector3Float
Checker.Int = Vector3Int
Checker.Type = "Vector3"
Checker._TypeOf = {Checker.Type}

return function()
    return Checker
end :: TypeCheckerConstructor<Vector3TypeChecker>