--!native
--!optimize 2

if (not script and Instance) then
    script = game:GetService("ReplicatedFirst").TypeGuard.Roblox.UDim2
end

local Template = require(script.Parent.Parent._Template)
    type TypeCheckerConstructor<T, P...> = Template.TypeCheckerConstructor<T, P...>
    type TypeChecker<ExtensionClass, Primitive> = Template.TypeChecker<ExtensionClass, Primitive>

type UDim2TypeChecker = TypeChecker<UDim2TypeChecker, UDim2> & {

};

local Core = script.Parent.Parent.Core
    local Indexable = require(Core.Indexable)

local UDim = require(script.Parent.UDim)
    local DefaultUDim = UDim()

local Checker = Indexable({
    X = DefaultUDim;
    Y = DefaultUDim;
}):Unmap(function(Value)
    return UDim2.new(Value.X, Value.Y)
end):Strict():NoConstraints()

Checker = Checker:Modify({
    Name = "UDim2";
    _TypeOf = {"UDim2"};
})

table.freeze(Checker)

return function()
    return Checker
end :: TypeCheckerConstructor<UDim2TypeChecker>