--!native
--!optimize 2

if (not script) then
    script = game:GetService("ReplicatedFirst").TypeGuard.Roblox.Ray
end

local Template = require(script.Parent.Parent._Template)
    type TypeCheckerConstructor<T, P...> = Template.TypeCheckerConstructor<T, P...>
    type FunctionalArg<T> = Template.FunctionalArg<T>
    type TypeChecker<ExtensionClass, Primitive> = Template.TypeChecker<ExtensionClass, Primitive>

type RayTypeChecker = TypeChecker<RayTypeChecker, Ray> & {

};

local Core = script.Parent.Parent.Core
    local Object = require(Core.Object)

local Vector3Serializer = require(script.Parent.Vector3)
    local DefaultVector3 = Vector3Serializer()

local Checker = Object({
    Direction = DefaultVector3;
    Origin = DefaultVector3;
}):Unmap(function(Value)
    return Ray.new(Value.Origin, Value.Direction)
end):Strict():NoConstraints()
--[[ Checker.Type = "Ray"
Checker._TypeOf = {Checker.Type} ]]

Checker = Checker:Modify({
    Type = "Ray";
    _TypeOf = {"Ray"};
})

return function()
    return Checker
end :: TypeCheckerConstructor<RayTypeChecker>