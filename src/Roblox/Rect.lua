--!native
--!optimize 2

if (not script and Instance) then
    script = game:GetService("ReplicatedFirst").TypeGuard.Roblox.Rect
end

local Template = require(script.Parent.Parent._Template)
    type TypeCheckerConstructor<T, P...> = Template.TypeCheckerConstructor<T, P...>
    type FunctionalArg<T> = Template.FunctionalArg<T>
    type TypeChecker<ExtensionClass, Primitive> = Template.TypeChecker<ExtensionClass, Primitive>

type RectTypeChecker = TypeChecker<RectTypeChecker, Rect> & {

};

local Core = script.Parent.Parent.Core
    local Indexable = require(Core.Indexable)

local Vector2Serializer = require(script.Parent.Vector2)
    local DefaultVector2 = Vector2Serializer()

local Checker = Indexable({
    Min = DefaultVector2;
    Max = DefaultVector2;
}):Unmap(function(Value)
    return Rect.new(Value.Min, Value.Max)
end):Strict():NoConstraints()

Checker = Checker:Modify({
    Name = "Rect";
    _TypeOf = {"Rect"};
})

table.freeze(Checker)

return function()
    return Checker
end :: TypeCheckerConstructor<RectTypeChecker>