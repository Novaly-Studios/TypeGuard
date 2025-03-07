--!native
--!optimize 2

if (not script) then
    script = game:GetService("ReplicatedFirst").TypeGuard.Roblox.Axes
end

local Template = require(script.Parent.Parent._Template)
    type TypeCheckerConstructor<T, P...> = Template.TypeCheckerConstructor<T, P...>
    type FunctionalArg<T> = Template.FunctionalArg<T>
    type TypeChecker<ExtensionClass, Primitive> = Template.TypeChecker<ExtensionClass, Primitive>
    type SelfReturn<T, P...> = Template.SelfReturn<T, P...>

type AxesTypeChecker = TypeChecker<AxesTypeChecker, Axes> & {

};

local Core = script.Parent.Parent.Core
    local Boolean = require(Core.Boolean)
        local DefaultBoolean = Boolean()
        local NonSerializedBoolean = Boolean():NonSerialized();
    local Object = require(Core.Object)

local Checker = Object({
    X = NonSerializedBoolean;
    Y = NonSerializedBoolean;
    Z = NonSerializedBoolean;

    Front = DefaultBoolean;
    Back = NonSerializedBoolean;
    Right = DefaultBoolean;
    Left = NonSerializedBoolean;
    Top = DefaultBoolean;
    Bottom = NonSerializedBoolean;
}):Unmap(function(Value)
    return Axes.new(
        Value.Front and Enum.NormalId.Front or nil,
        Value.Right and Enum.NormalId.Right or nil,
        Value.Top and Enum.NormalId.Top or nil
    )
end):Strict():NoConstraints()
Checker.Type = "Axes"
Checker._TypeOf = {Checker.Type}

return function()
    return Checker
end :: TypeCheckerConstructor<AxesTypeChecker>