--!native
--!optimize 2

if (not script and Instance) then
    script = game:GetService("ReplicatedFirst").TypeGuard.Roblox.Vector2
end

local Template = require(script.Parent.Parent._Template)
    type TypeCheckerConstructor<T, P...> = Template.TypeCheckerConstructor<T, P...>
    type FunctionalArg<T> = Template.FunctionalArg<T>
    type TypeChecker<ExtensionClass, Primitive> = Template.TypeChecker<ExtensionClass, Primitive>

type Vector2TypeChecker = TypeChecker<Vector2TypeChecker, Vector2> & {

};

local Core = script.Parent.Parent.Core
    local Indexable = require(Core.Indexable)
    local Number = require(Core.Number)
        local Float32 = Number():Float(32)

local Checker = Indexable({
    X = Float32;
    Y = Float32;
}):Unmap(function(Value)
    return Vector2.new(Value.X, Value.Y)
end):Strict():NoConstraints()

Checker = Checker:Modify({
    Name = "Vector2";
    _TypeOf = {"Vector2"};
})

table.freeze(Checker)

return function()
    return Checker
end :: TypeCheckerConstructor<Vector2TypeChecker>