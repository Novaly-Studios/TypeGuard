--!native
--!optimize 2

if (not script and Instance) then
    script = game:GetService("ReplicatedFirst").TypeGuard.Roblox.Axes
end

local Template = require(script.Parent.Parent._Template)
    type TypeCheckerConstructor<T, P...> = Template.TypeCheckerConstructor<T, P...>
    type FunctionalArg<T> = Template.FunctionalArg<T>
    type TypeChecker<ExtensionClass, Primitive> = Template.TypeChecker<ExtensionClass, Primitive>

type AxesTypeChecker = TypeChecker<AxesTypeChecker, Axes> & {

};

local Core = script.Parent.Parent.Core
    local Boolean = require(Core.Boolean)
        local DefaultBoolean = Boolean()
    local Object = require(Core.Object)

local Checker = Object({
    Front = DefaultBoolean;
    Right = DefaultBoolean;
    Top = DefaultBoolean;
}):Unmap(function(Value)
    return Axes.new(
        Value.Front and Enum.NormalId.Front or nil,
        Value.Right and Enum.NormalId.Right or nil,
        Value.Top and Enum.NormalId.Top or nil
    )
end):Strict():NoConstraints()

Checker = Checker:Modify({
    Name = "Axes";
    _TypeOf = {"Axes"};
})

table.freeze(Checker)

return function()
    return Checker
end :: TypeCheckerConstructor<AxesTypeChecker>