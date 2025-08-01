--!native
--!optimize 2

if (not script and Instance) then
    script = game:GetService("ReplicatedFirst").TypeGuard.Roblox.FloatCurveKey
end

local Template = require(script.Parent.Parent._Template)
    type TypeCheckerConstructor<T, P...> = Template.TypeCheckerConstructor<T, P...>
    type FunctionalArg<T> = Template.FunctionalArg<T>
    type TypeChecker<ExtensionClass, Primitive> = Template.TypeChecker<ExtensionClass, Primitive>

type FloatCurveKeyTypeChecker = TypeChecker<FloatCurveKeyTypeChecker, FloatCurveKey> & {

};

local Core = script.Parent.Parent.Core
    local Indexable = require(Core.Indexable)
    local Optional = require(Core.Optional)
    local Number = require(Core.Number)
        local Float32 = Number():Float(32)

local RbxEnum = require(script.Parent.Enum)
    local EnumKeyInterpolationMode = RbxEnum(Enum.KeyInterpolationMode)

local Checker = Indexable({
    Interpolation = EnumKeyInterpolationMode;
    RightTangent = Optional(Float32);
    LeftTangent = Optional(Float32);
    Value = Float32;
    Time = Float32;
}):Unmap(function(Value)
    local Result = FloatCurveKey.new(Value.Time, Value.Value, Value.Interpolation)
    Result.RightTangent = Value.RightTangent
    Result.LeftTangent = Value.LeftTangent
    return Result
end):Strict():NoConstraints()

Checker = Checker:Modify({
    Name = "FloatCurveKey";
    _TypeOf = {"FloatCurveKey"};
})

table.freeze(Checker)

return function()
    return Checker
end :: TypeCheckerConstructor<FloatCurveKeyTypeChecker>