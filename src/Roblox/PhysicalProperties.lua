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

type PhysicalPropertiesTypeChecker = TypeChecker<PhysicalPropertiesTypeChecker, PhysicalProperties> & {

};

local Core = script.Parent.Parent.Core
    local Number = require(Core.Number)
    local Object = require(Core.Object)

local Checker = Object({
    ElasticityWeight = Number(0, 100):Float(32);
    FrictionWeight = Number(0, 100):Float(32);
    Elasticity = Number(0, 1):Float(32);
    Friction = Number(0, 2):Float(32);
    Density = Number(0.01, 100):Float(32);
}):Unmap(function(Value)
    return PhysicalProperties.new(
        Value.Density,
        Value.Friction,
        Value.Elasticity,
        Value.FrictionWeight,
        Value.ElasticityWeight
    )
end):Strict():NoConstraints()
Checker.Type = "PhysicalProperties"
Checker._TypeOf = {Checker.Type}

return function()
    return Checker
end :: TypeCheckerConstructor<PhysicalPropertiesTypeChecker>