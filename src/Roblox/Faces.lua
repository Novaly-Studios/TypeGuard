--!native
--!optimize 2

if (not script and Instance) then
    script = game:GetService("ReplicatedFirst").TypeGuard.Roblox.Faces
end

local Template = require(script.Parent.Parent._Template)
    type TypeCheckerConstructor<T, P...> = Template.TypeCheckerConstructor<T, P...>
    type FunctionalArg<T> = Template.FunctionalArg<T>
    type TypeChecker<ExtensionClass, Primitive> = Template.TypeChecker<ExtensionClass, Primitive>

type FacesTypeChecker = TypeChecker<FacesTypeChecker, Faces> & {

};

local Core = script.Parent.Parent.Core
    local Boolean = require(Core.Boolean)
        local DefaultBoolean = Boolean()
    local Object = require(Core.Object)

local Checker = Object({
    Front = DefaultBoolean;
    Back = DefaultBoolean;
    Right = DefaultBoolean;
    Left = DefaultBoolean;
    Top = DefaultBoolean;
    Bottom = DefaultBoolean;
}):Unmap(function(Value)
    return Faces.new(
        Value.Front and Enum.NormalId.Front or nil,
        Value.Back and Enum.NormalId.Back or nil,
        Value.Right and Enum.NormalId.Right or nil,
        Value.Left and Enum.NormalId.Left or nil,
        Value.Top and Enum.NormalId.Top or nil,
        Value.Bottom and Enum.NormalId.Bottom or nil
    )
end):Strict():NoConstraints()

Checker = Checker:Modify({
    Name = "Faces";
    _TypeOf = {"Faces"};
})

table.freeze(Checker)

return function()
    return Checker
end :: TypeCheckerConstructor<FacesTypeChecker>