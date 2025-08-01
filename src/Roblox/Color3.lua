--!native
--!optimize 2

if (not script and Instance) then
    script = game:GetService("ReplicatedFirst").TypeGuard.Roblox.Color3
end

local Template = require(script.Parent.Parent._Template)
    type TypeCheckerConstructor<T, P...> = Template.TypeCheckerConstructor<T, P...>
    type FunctionalArg<T> = Template.FunctionalArg<T>
    type TypeChecker<ExtensionClass, Primitive> = Template.TypeChecker<ExtensionClass, Primitive>

type Color3TypeChecker = TypeChecker<Color3TypeChecker, Color3> & {

};

local Core = script.Parent.Parent.Core
    local Number = require(Core.Number)
        local StandardRange = Number(0, 1)
    local Indexable = require(Core.Indexable)

local Checker = Indexable({
    R = StandardRange;
    G = StandardRange;
    B = StandardRange;
}):Unmap(function(Value)
    return Color3.new(Value.R, Value.G, Value.B)
end):Strict():NoConstraints()

Checker = Checker:Modify({
    Name = "Color3";
    _TypeOf = {"Color3"};
})

table.freeze(Checker)

return function()
    return Checker
end :: TypeCheckerConstructor<Color3TypeChecker>