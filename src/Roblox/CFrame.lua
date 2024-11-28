--!native
--!optimize 2

if (not script) then
    script = game:GetService("ReplicatedFirst").TypeGuard.Roblox.CFrame
end

local Template = require(script.Parent.Parent._Template)
    type TypeCheckerConstructor<T, P...> = Template.TypeCheckerConstructor<T, P...>
    type FunctionalArg<T> = Template.FunctionalArg<T>
    type TypeChecker<ExtensionClass, Primitive> = Template.TypeChecker<ExtensionClass, Primitive>
    type SelfReturn<T, P...> = Template.SelfReturn<T, P...>

type CFrameTypeChecker = TypeChecker<CFrameTypeChecker, CFrame> & {
    Float: SelfReturn<CFrameTypeChecker, FunctionalArg<number>>;
};

local Core = script.Parent.Parent.Core
    local Number = require(Core.Number)
        local Float32 = Number():Float(32)
    local Object = require(Core.Object)
    local Array = require(Core.Array)

local function CFrameFloat(self, Precision)
    local Float = Number():Float(Precision)
    return self:_MapCheckers("Number", function(Checker)
        return Float
    end, true)
end

local Intermediary = Object({
    X = Float32;
    Y = Float32;
    Z = Float32;
    AxisX = Float32;
    AxisY = Float32;
    AxisZ = Float32;
    Angle = Float32;
}):Strict():NoCheck()
--[[ local Intermediary = Array():OfStructure({
    Float32;
    Float32;
    Float32;
    Float32;
    Float32;
    Float32;
    Float32;
}):Strict():NoCheck() ]]

local Checker = Object():MapStructure(Intermediary, function(Value)
    local Position = Value.Position
    local Axis, Angle = Value:ToAxisAngle()

    --[[ return {
        Position.X;
        Position.Y;
        Position.Z;
        Axis.X;
        Axis.Y;
        Axis.Z;
        Angle;
    } ]]
    return {
        X = Position.X;
        Y = Position.Y;
        Z = Position.Z;
        AxisX = Axis.X;
        AxisY = Axis.Y;
        AxisZ = Axis.Z;
        Angle = Angle;
    }
end):UnmapStructure(function(Value)
    --[[ return CFrame.new(Value[1], Value[2], Value[3]) * CFrame.fromAxisAngle(
        Vector3.new(Value[4], Value[5], Value[6]), Value[7]
    ) ]]
    return CFrame.new(Value.X, Value.Y, Value.Z) * CFrame.fromAxisAngle(
        Vector3.new(Value.AxisX, Value.AxisY, Value.AxisZ), Value.Angle
    )
end):Strict():NoConstraints()
Checker.Float = CFrameFloat
Checker.Type = "CFrame"
Checker._TypeOf = {Checker.Type}

return function()
    return Checker
end :: TypeCheckerConstructor<CFrameTypeChecker>