--!native
--!optimize 2

if (not script and Instance) then
    script = game:GetService("ReplicatedFirst").TypeGuard.Roblox.RotationCurveKey
end

local Template = require(script.Parent.Parent._Template)
    type TypeCheckerConstructor<T, P...> = Template.TypeCheckerConstructor<T, P...>
    type FunctionalArg<T> = Template.FunctionalArg<T>
    type TypeChecker<ExtensionClass, Primitive> = Template.TypeChecker<ExtensionClass, Primitive>

type RotationCurveKeyTypeChecker = TypeChecker<RotationCurveKeyTypeChecker, RotationCurveKey> & {

};

local Core = script.Parent.Parent.Core
    local Number = require(Core.Number)
        local DefaultNumber = Number()
    local Object = require(Core.Object)

local RbxEnum = require(script.Parent.Enum)
    local EnumKeyInterpolationMode = RbxEnum(Enum.KeyInterpolationMode)

local RbxCFrame = require(script.Parent.CFrame)
    local DefaultCFrame = RbxCFrame()

local Checker = Object({
    Interpolation = EnumKeyInterpolationMode;
    RightTangent = DefaultNumber;
    LeftTangent = DefaultNumber;
    Value = DefaultCFrame;
    Time = DefaultNumber;
}):Unmap(function(Value)
    local Result = RotationCurveKey.new(Value.Time, Value.Value, Value.Interpolation)
    Result.RightTangent = Value.RightTangent
    Result.LeftTangent = Value.LeftTangent
    return Result
end):Strict():NoConstraints()

Checker = Checker:Modify({
    Name = "RotationCurveKey";
    _TypeOf = {"RotationCurveKey"};
})

table.freeze(Checker)

return function()
    return Checker
end :: TypeCheckerConstructor<RotationCurveKeyTypeChecker>