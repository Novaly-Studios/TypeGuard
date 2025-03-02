--!native
--!optimize 2

if (not script) then
    script = game:GetService("ReplicatedFirst").TypeGuard.Roblox.Ray
end

local Template = require(script.Parent.Parent._Template)
    type TypeCheckerConstructor<T, P...> = Template.TypeCheckerConstructor<T, P...>
    type FunctionalArg<T> = Template.FunctionalArg<T>
    type TypeChecker<ExtensionClass, Primitive> = Template.TypeChecker<ExtensionClass, Primitive>
    type SelfReturn<T, P...> = Template.SelfReturn<T, P...>

type RayTypeChecker = TypeChecker<RayTypeChecker, Ray> & {
    Float: SelfReturn<RayTypeChecker, FunctionalArg<number>>;
    Int: SelfReturn<RayTypeChecker, FunctionalArg<number>, FunctionalArg<boolean>>;
};

local Core = script.Parent.Parent.Core
    local Number = require(Core.Number)
    local Object = require(Core.Object)

local Vector3Serializer = require(script.Parent.Vector3)
    local DefaultVector3 = Vector3Serializer()

local function RayFloat(self, Precision)
    local Float = Number():Float(Precision)

    return self:_MapCheckers("Vector3", function(Checker)
        return Float
    end)
end

local function RayInt(self, Bits, Unsigned)
    local Int = Number():Integer(Bits, Unsigned)

    return self:_MapCheckers("Vector3", function(Checker)
        return Int
    end)
end

local Checker = Object({
    Direction = DefaultVector3;
    Origin = DefaultVector3;
}):Unmap(function(Value)
    return Ray.new(Value.Origin, Value.Direction)
end):Strict():NoConstraints()
Checker.Float = RayFloat
Checker.Int = RayInt
Checker.Type = "Ray"
Checker._TypeOf = {Checker.Type}

return function()
    return Checker
end :: TypeCheckerConstructor<RayTypeChecker>