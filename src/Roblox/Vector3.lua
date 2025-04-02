--!native
--!optimize 2

if (not script and Instance) then
    script = game:GetService("ReplicatedFirst").TypeGuard.Roblox.Vector3
end

local Template = require(script.Parent.Parent._Template)
    type TypeCheckerConstructor<T, P...> = Template.TypeCheckerConstructor<T, P...>
    type FunctionalArg<T> = Template.FunctionalArg<T>
    type TypeChecker<ExtensionClass, Primitive> = Template.TypeChecker<ExtensionClass, Primitive>

type Vector3TypeChecker = TypeChecker<Vector3TypeChecker, Vector3> & {

};

local Core = script.Parent.Parent.Core
    local Number = require(Core.Number)
        local Float32 = Number():Float(32)
    local Object = require(Core.Object)

local Checker = Object({
    X = Float32;
    Y = Float32;
    Z = Float32;
}):Unmap(function(Value)
    return Vector3.new(Value.X, Value.Y, Value.Z)
end):Strict():NoConstraints()

Checker = Checker:Modify({
    Name = "Vector3";
    _TypeOf = {"Vector3"};
})

table.freeze(Checker)

return function()
    return Checker
end :: TypeCheckerConstructor<Vector3TypeChecker>