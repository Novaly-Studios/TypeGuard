--!native
--!optimize 2

if (not script and Instance) then
    script = game:GetService("ReplicatedFirst").TypeGuard.Roblox.CFrame
end

local Template = require(script.Parent.Parent._Template)
    type TypeCheckerConstructor<T, P...> = Template.TypeCheckerConstructor<T, P...>
    type FunctionalArg<T> = Template.FunctionalArg<T>
    type TypeChecker<ExtensionClass, Primitive> = Template.TypeChecker<ExtensionClass, Primitive>

type CFrameTypeChecker = TypeChecker<CFrameTypeChecker, CFrame> & {
    Compressed: ((self: CFrameTypeChecker, Clicks: number?) -> (CFrameTypeChecker));
};

local Core = script.Parent.Parent.Core
    local Indexable = require(Core.Indexable)
    local Number = require(Core.Number)
        local Float32 = Number():Float(32)

local Intermediary = Indexable({
    X = Float32;
    Y = Float32;
    Z = Float32;
    R00 = Float32;
    R01 = Float32;
    R02 = Float32;
    R10 = Float32;
    R11 = Float32;
    R12 = Float32;
    R20 = Float32;
    R21 = Float32;
    R22 = Float32;
}):Strict():NoCheck()

local Checker = Indexable():MapStructure(Intermediary, function(Value)
    local X, Y, Z, R00, R01, R02, R10, R11, R12, R20, R21, R22 = Value:GetComponents()

    return {
        X = X;
        Y = Y;
        Z = Z;
        R00 = R00;
        R01 = R01;
        R02 = R02;
        R10 = R10;
        R11 = R11;
        R12 = R12;
        R20 = R20;
        R21 = R21;
        R22 = R22;
    }
end):UnmapStructure(function(Value)
    return CFrame.new(
        Value.X, Value.Y, Value.Z,
        Value.R00, Value.R01, Value.R02,
        Value.R10, Value.R11, Value.R12,
        Value.R20, Value.R21, Value.R22
    )
end):Strict():NoConstraints()

function Checker:Compressed(Clicks)
    Clicks = Clicks or 256

    local Bits = math.ceil(math.log(Clicks, 2))
    assert(Bits <= 10, "Clicks must be at most 1024")

    local Bits2 = Bits * 2
    local Fill = 2 ^ Bits - 1
    local Tau = math.pi * 2

    local CompressedIntermediary = Indexable({
        X = Float32;
        Y = Float32;
        Z = Float32;
        Angle = Number():Integer(Bits * 3, false);
    }):Strict():NoCheck()

    return self:MapStructure(CompressedIntermediary, function(Value)
        local Position = Value.Position
        local Y, P, R = Value:ToEulerAnglesYXZ()
        Y = ((Y % Tau) / Tau * Clicks) // 1
        P = ((P % Tau) / Tau * Clicks) // 1
        R = ((R % Tau) / Tau * Clicks) // 1

        local Angle = bit32.bor(Y, bit32.lshift(P, Bits), bit32.lshift(R, Bits2))

        return {
            Angle = Angle;
            X = Position.X;
            Y = Position.Y;
            Z = Position.Z;
        }
    end):UnmapStructure(function(Value)
        local Angle = Value.Angle
        local Y = bit32.band(Angle, Fill) / Clicks * Tau
        local P = bit32.band(bit32.rshift(Angle, Bits), Fill) / Clicks * Tau
        local R = bit32.band(bit32.rshift(Angle, Bits2), Fill) / Clicks * Tau

        return CFrame.new(Value.X, Value.Y, Value.Z) * CFrame.fromEulerAnglesYXZ(Y, P, R)
    end)
end

Checker = Checker:Modify({
    Name = "CFrame";
    _TypeOf = {"CFrame"};
})

table.freeze(Checker)

return function()
    return Checker
end :: TypeCheckerConstructor<CFrameTypeChecker>