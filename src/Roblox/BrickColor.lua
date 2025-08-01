--!native
--!optimize 2

if (not script and Instance) then
    script = game:GetService("ReplicatedFirst").TypeGuard.Roblox.BrickColor
end

local Template = require(script.Parent.Parent._Template)
    type TypeCheckerConstructor<T, P...> = Template.TypeCheckerConstructor<T, P...>
    type FunctionalArg<T> = Template.FunctionalArg<T>
    type TypeChecker<ExtensionClass, Primitive> = Template.TypeChecker<ExtensionClass, Primitive>

type BrickColorTypeChecker = TypeChecker<BrickColorTypeChecker, BrickColor> & {

};

local Core = script.Parent.Parent.Core
    local Indexable = require(Core.Indexable)
    local Number = require(Core.Number)

local Checker = Indexable({
    Number = Number(0, 1032):Integer();
}):Unmap(function(Value)
    return BrickColor.new(Value.Number)
end):Strict():NoConstraints()

Checker = Checker:Modify({
    Name = "BrickColor";
    _TypeOf = {"BrickColor"};
})

table.freeze(Checker)

return function()
    return Checker
end :: TypeCheckerConstructor<BrickColorTypeChecker>