--!native
--!optimize 2

if (not script) then
    script = game:GetService("ReplicatedFirst").TypeGuard.Roblox.Ray
end

local Template = require(script.Parent.Parent._Template)
    type TypeCheckerConstructor<T, P...> = Template.TypeCheckerConstructor<T, P...>
    type FunctionalArg<T> = Template.FunctionalArg<T>
    type TypeChecker<ExtensionClass, Primitive> = Template.TypeChecker<ExtensionClass, Primitive>

type Path2DControlPointTypeChecker = TypeChecker<Path2DControlPointTypeChecker, Path2DControlPoint> & {

};

local Core = script.Parent.Parent.Core
    local Object = require(Core.Object)

local RbxUDim2 = require(script.Parent.UDim2)
    local DefaultUDim2 = RbxUDim2()

local Checker = Object({
    RightTangent = DefaultUDim2;
    LeftTangent = DefaultUDim2;
    Position = DefaultUDim2;
}):Unmap(function(Value)
    return Path2DControlPoint.new(Value.Position, Value.LeftTangent, Value.RightTangent)
end):Strict():NoConstraints()
--[[ Checker.Type = "Path2DControlPoint"
Checker._TypeOf = {Checker.Type} ]]

Checker = Checker:Modify({
    Type = "Path2DControlPoint";
    _TypeOf = {"Path2DControlPoint"};
})

return function()
    return Checker
end :: TypeCheckerConstructor<Path2DControlPointTypeChecker>