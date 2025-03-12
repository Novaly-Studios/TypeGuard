--!native
--!optimize 2

if (not script) then
    script = game:GetService("ReplicatedFirst").TypeGuard.Roblox.BrickColor
end

local Template = require(script.Parent.Parent._Template)
    type TypeCheckerConstructor<T, P...> = Template.TypeCheckerConstructor<T, P...>
    type FunctionalArg<T> = Template.FunctionalArg<T>
    type TypeChecker<ExtensionClass, Primitive> = Template.TypeChecker<ExtensionClass, Primitive>

type BrickColorTypeChecker = TypeChecker<BrickColorTypeChecker, BrickColor> & {

};

local Core = script.Parent.Parent.Core
    local Number = require(Core.Number)
    local Object = require(Core.Object)
    local String = require(Core.String)

local Color3Serializer = require(script.Parent.Color3)()

local Checker = Object({
    Number = Number(0, 1032):Integer();
    Color = Color3Serializer:NonSerialized();
    Name = String():NonSerialized();
    r = Number(0, 1):NonSerialized();
    g = Number(0, 1):NonSerialized();
    b = Number(0, 1):NonSerialized();
}):Unmap(function(Value)
    return BrickColor.new(Value.Number)
end):Strict():NoConstraints()
--[[ Checker.Type = "BrickColor"
Checker._TypeOf = {Checker.Type} ]]

Checker = Checker:Modify({
    Type = "BrickColor";
    _TypeOf = {"BrickColor"};
})

return function()
    return Checker
end :: TypeCheckerConstructor<BrickColorTypeChecker>