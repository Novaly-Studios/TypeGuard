--!native
--!optimize 2

if (not script and Instance) then
    script = game:GetService("ReplicatedFirst").TypeGuard.Core.Number
end

local Template = require(script.Parent.Parent._Template)
    type TypeCheckerConstructor<T, P...> = Template.TypeCheckerConstructor<T, P...>
    type FunctionalArg<T> = Template.FunctionalArg<T>
    type TypeChecker<ExtensionClass, Primitive> = Template.TypeChecker<ExtensionClass, Primitive>

local Util = require(script.Parent.Parent.Util)
    local CreateStandardInitial = Util.CreateStandardInitial
    local ExpectType = Util.ExpectType
    local Expect = Util.Expect

export type NumberTypeChecker = TypeChecker<NumberTypeChecker, number> & {
    RangeInclusive: ((self: NumberTypeChecker, Start: FunctionalArg<number>, End: FunctionalArg<number>) -> (NumberTypeChecker));
    RangeExclusive: ((self: NumberTypeChecker, Start: FunctionalArg<number>, End: FunctionalArg<number>) -> (NumberTypeChecker));
    IsInfinite: ((self: NumberTypeChecker) -> (NumberTypeChecker));
    Positive: ((self: NumberTypeChecker) -> (NumberTypeChecker));
    Negative: ((self: NumberTypeChecker) -> (NumberTypeChecker));
    IsClose: ((self: NumberTypeChecker, Target: FunctionalArg<number>, Tolerance: FunctionalArg<number>) -> (NumberTypeChecker));
    Integer: ((self: NumberTypeChecker, Bits: FunctionalArg<number?>, Signed: FunctionalArg<boolean?>) -> (NumberTypeChecker));
    Decimal: ((self: NumberTypeChecker) -> (NumberTypeChecker));
    Dynamic: ((self: NumberTypeChecker) -> (NumberTypeChecker));
    Float: ((self: NumberTypeChecker, Bits: FunctionalArg<number>) -> (NumberTypeChecker));
    IsNaN: ((self: NumberTypeChecker) -> (NumberTypeChecker));
};

local FLOAT_MAX_32 = 3.402823466e+38
local FLOAT_MAX_64 = 1.7976931348623157e+308

local Number: ((Min: FunctionalArg<number?>, Max: FunctionalArg<number?>) -> (NumberTypeChecker)), NumberClass = Template.Create("Number")
NumberClass._CacheConstruction = true
NumberClass._Initial = CreateStandardInitial("number")
NumberClass._TypeOf = {"number"}

local function _Whole(_, Item)
    if (Item % 1 == 0) then
        return true
    end

    return false, `Expected integer form, got {Item}`
end

local function _ConstrainToRange(Value, Min, Max)
    if (Value < Min) then
        return false, `Expected integer in the range of ({Min} to {Max}), got {Value}, lower than minimum {Min}`
    end

    if (Value > Max) then
        return false, `Expected integer in the range of ({Min} to {Max}), got {Value}, higher than maximum {Max}`
    end

    return true
end

local function _Integer(self, Value, Bits, Signed)
    local Positive = self:HasConstraint("Positive")
    local Negative = self:HasConstraint("Negative")
    local Dynamic = self._Dynamic

    if (Bits == 0) then
        return _ConstrainToRange(Value, 0, 0)
    end

    if (Dynamic) then
        if (Positive) then
            return _ConstrainToRange(Value, 0, 2 ^ Bits - 1)
        end

        if (Negative) then
            return _ConstrainToRange(Value, -2 ^ Bits, -1)
        end

        return _ConstrainToRange(Value, -2 ^ Bits, 2 ^ Bits - 1)
    end

    if (Negative) then
        return _ConstrainToRange(Value, -2 ^ Bits, -1)
    end

    if (Signed and not (Positive or Negative)) then
        local Less = Bits - 1
        return _ConstrainToRange(Value, -2 ^ Less, 2 ^ Less - 1)
    end

    -- Default: unsigned -> positive, or positive explicitly defined.
    return _ConstrainToRange(Value, 0, 2 ^ Bits - 1)
end

--- Checks if the value is whole.
function NumberClass:Integer(Bits, Signed)
    Signed = if (Signed == nil) then true else Signed
    Bits = Bits or 32
    return self:_AddConstraint(true, "Whole", _Whole):_AddConstraint(true, "Integer", _Integer, Bits, Signed)
end

local function _Decimal(_, Item)
    if (Item % 1 ~= 0) then
        return true
    end

    return false, `Expected decimal form, got {Item}`
end

--- Checks if the number is not whole.
function NumberClass:Decimal()
    return self:_AddConstraint(true, "Decimal", _Decimal)
end

--- Makes an int dynamically sized during serialization.
function NumberClass:Dynamic()
    return self:Modify({
        _Dynamic = true;
    })
end

--- Ensures a number is between or equal to a minimum and maximum value. Can also function as "equals" - useful for this being used as the InitialConstraint.
function NumberClass:RangeInclusive(Min, Max)
    ExpectType(Min, Expect.NUMBER_OR_FUNCTION, 1)
    Max = (Max == nil and Min or Max)
    ExpectType(Max, Expect.NUMBER_OR_FUNCTION, 2)

    if (Max == Min) then
        return self:Equals(Min)
    end

    if ((type(Max) == "number" or type(Min) == "number") and (Max < Min)) then
        error(`Max value {Max} is less than min value {Min}`)
    end

    return self:GreaterThanOrEqualTo(Min):LessThanOrEqualTo(Max)
end

--- Ensures a number is between but not equal to a minimum and maximum value.
function NumberClass:RangeExclusive(Min, Max)
    return self:GreaterThan(Min):LessThan(Max)
end

local function _Positive(_, Item)
    if (Item < 0) then
        return false, `Expected positive number, got {Item}`
    end

    return true
end

--- Checks the number is positive.
function NumberClass:Positive()
    return self:_AddConstraint(true, "Positive", _Positive)
end

local function _Negative(_, Item)
    if (Item >= 0) then
        return false, `Expected negative number, got {Item}`
    end

    return true
end

--- Checks the number is negative.
function NumberClass:Negative()
    return self:_AddConstraint(true, "Negative", _Negative)
end

local function _IsNaN(_, Item)
    if (Item ~= Item) then
        return true
    end

    return false, `Expected NaN, got {Item}`
end

--- Checks if the number is NaN.
function NumberClass:IsNaN()
    return self:_AddConstraint(true, "IsNaN", _IsNaN)
end

local function _IsInfinite(_, Item)
    if (Item == math.huge or Item == -math.huge) then
        return true
    end

    return false, `Expected infinite, got {Item}`
end

--- Checks if the number is infinite.
function NumberClass:IsInfinite()
    return self:_AddConstraint(true, "IsInfinite", _IsInfinite)
end

local function _Float()
    return true
end

--- Checks if the number has a range fit for floats of the precision given.
function NumberClass:Float(Precision)
    local MaxValue = ((Precision or 64) > 33 and FLOAT_MAX_64 or FLOAT_MAX_32)
    return self:_AddConstraint(true, "Float", _Float, MaxValue):RangeInclusive(-MaxValue, MaxValue)
end

local function _IsCloseTo(_, NumberValue, CloseTo, Tolerance)
    if (math.abs(NumberValue - CloseTo) < Tolerance) then
        return true
    end

    return false, `Expected {CloseTo} +/- {Tolerance}, got {NumberValue}`
end

--- Checks if the number is close to another.
function NumberClass:IsClose(CloseTo, Tolerance)
    ExpectType(CloseTo, Expect.NUMBER_OR_FUNCTION, 1)
    Tolerance = Tolerance or 0.00001

    return self:_AddConstraint(true, "IsClose", _IsCloseTo, CloseTo, Tolerance)
end

local NaN = 0 / 0
function NumberClass:_UpdateSerialize()
    local MysteriousNumber = { -- Default to double if we don't know many details about the number. Largest number type in Luau.
        _Serialize = function(Buffer, Value, _Context)
            local BufferContext = Buffer.Context

            if (BufferContext) then
                BufferContext("Number")
            end

            Buffer.WriteFloat(64, Value)

            if (BufferContext) then
                BufferContext()
            end
        end;
        _Deserialize = function(Buffer, _Context)
            return Buffer.ReadFloat(64)
        end;
    }

    if (self:_HasFunctionalConstraints()) then
        return MysteriousNumber
    end

    if (self:GetConstraint("IsInfinite")) then
        return {
            _Serialize = function(Buffer, Value, _Context)
                local BufferContext = Buffer.Context

                if (BufferContext) then
                    BufferContext("Number(IsInfinite)")
                end

                Buffer.WriteUInt(1, Value == math.huge and 1 or 0)

                if (BufferContext) then
                    BufferContext()
                end
            end;
            _Deserialize = function(Buffer, _Context)
                return (Buffer.ReadUInt(1) == 1 and math.huge or -math.huge)
            end;
        }
    end

    if (self:GetConstraint("IsNaN")) then
        return {
            _Serialize = function(Buffer, _, _)
                local BufferContext = Buffer.Context

                if (BufferContext) then
                    BufferContext("Number(IsNaN)")
                    BufferContext()
                end
            end;
            _Deserialize = function(_, _)
                return NaN
            end;
        }
    end

    local Float = self:GetConstraint("Float")

    if (Float) then
        local Bits = Float[1]
        local ContextString = `Number(Float{Bits})`

        return {
            _Serialize = function(Buffer, Value, _Context)
                local BufferContext = Buffer.Context

                if (BufferContext) then
                    BufferContext(ContextString)
                end

                Buffer.WriteFloat(Bits, Value)

                if (BufferContext) then
                    BufferContext()
                end
            end;
            _Deserialize = function(Buffer, _Context)
                return Buffer.ReadFloat(Bits)
            end;
        }
    end

    -- Multiple range constraints can exist, so find the boundaries here.
    local Min
    local Max

    for _, Args in self:GetConstraints("GreaterThanOrEqualTo") do
        local Value = Args[1]
        Min = math.min(Min or Value, Value)
    end

    for _, Args in self:GetConstraints("LessThanOrEqualTo") do
        local Value = Args[1]
        Max = math.max(Max or Value, Value)
    end

    local Integer = self:GetConstraint("Integer")

    --#region Integers
    if (Integer) then
        local DefinedBits = Integer[1]
        local Dynamic = self._Dynamic
        local Unsigned = (not Integer[2])
        local Positive = (self:GetConstraint("Positive") or (Min and Min >= 0 and Max and Max >= 0) or Unsigned)
        local Negative = (self:GetConstraint("Negative") or (Min and Min < 0 and Max and Max < 0))

        if (Dynamic) then
            -- Integer with known sign -> no need to store sign, just use UInt.
            if (Positive or Negative) then
                local ContextString = (Negative and "Number(Integer, Dynamic, Negative)" or "Number(Integer, Dynamic, Positive)")

                return {
                    _Serialize = function(Buffer, Value, _Context)
                        local BufferContext = Buffer.Context

                        if (BufferContext) then
                            BufferContext(ContextString)
                        end

                        Value = (Negative and (-Value - 1) or Value)

                        local Bits = 32 - bit32.countlz(Value)
                        local WriteUInt = Buffer.WriteUInt
                        WriteUInt(6, Bits)
                        WriteUInt(Bits, Value)

                        if (BufferContext) then
                            BufferContext()
                        end
                    end;
                    _Deserialize = function(Buffer, _Context)
                        local ReadUInt = Buffer.ReadUInt
                        local Value = ReadUInt(ReadUInt(6))

                        return (Negative and (-Value - 1) or Value)
                    end;
                }
            end

            -- Resort to: signed dynamic integer (+1 bit).
            return {
                _Serialize = function(Buffer, Value, _Context)
                    local BufferContext = Buffer.Context

                    if (BufferContext) then
                        BufferContext("Number(Dynamic, Integer)")
                    end

                    local IsNegative = (Value < 0)
                    Value = (IsNegative and (-Value - 1) or Value)

                    local Bits = 32 - bit32.countlz(Value)
                    local Metadata = bit32.bor(Bits, IsNegative and 0b1000000 or 0)
                    local WriteUInt = Buffer.WriteUInt
                    WriteUInt(7, Metadata)

                    if (Bits > 0) then
                        WriteUInt(Bits, Value)
                    end

                    if (BufferContext) then
                        BufferContext()
                    end
                end;
                _Deserialize = function(Buffer, _Context)
                    local ReadUInt = Buffer.ReadUInt
                    local Metadata = ReadUInt(7)
                    local Bits = bit32.band(Metadata, 0b0111111)
                    local Positive = (bit32.band(Metadata, 0b1000000) == 0)
                    local Value = ReadUInt(Bits)

                    return (Positive and Value or (-Value - 1))
                end;
            }
        end

        -- The number of bits required to store the integer can be reduced if the range
        -- is known to be between two concrete values.
        if (Min and Max) then
            local Bits = math.log(math.abs(Max - Min), 2) // 1 + 1
            local ContextString = `Number(Whole, Min {Min}, Max {Max}))`

            return {
                _Serialize = function(Buffer, Value, _Context)
                    local BufferContext = Buffer.Context

                    if (BufferContext) then
                        BufferContext(ContextString)
                    end

                    Buffer.WriteUInt(Bits, Value - Min)

                    if (BufferContext) then
                        BufferContext()
                    end
                end;
                _Deserialize = function(Buffer, _Context)
                    return Buffer.ReadUInt(Bits) + Min
                end;
            }
        end

        -- Positive: use UInt.
        if (Positive) then
            DefinedBits = DefinedBits or 32
            local ContextString = `Number(UInt{DefinedBits})`

            return {
                _Serialize = function(Buffer, Value, _Context)
                    local BufferContext = Buffer.Context

                    if (BufferContext) then
                        BufferContext(ContextString)
                    end

                    Buffer.WriteUInt(DefinedBits, Value)

                    if (BufferContext) then
                        BufferContext()
                    end
                end;
                _Deserialize = function(Buffer, _Context)
                    return Buffer.ReadUInt(DefinedBits)
                end;
            }
        end

        -- Negative: use UInt.
        if (Negative) then
            DefinedBits = DefinedBits or 32
            local ContextString = `Number(UInt{DefinedBits})`

            return {
                _Serialize = function(Buffer, Value, _Context)
                    local BufferContext = Buffer.Context

                    if (BufferContext) then
                        BufferContext(ContextString)
                    end

                    Buffer.WriteUInt(DefinedBits, -Value - 1)

                    if (BufferContext) then
                        BufferContext()
                    end
                end;
                _Deserialize = function(Buffer, _Context)
                    return -Buffer.ReadUInt(DefinedBits) - 1
                end;
            }
        end

        -- Last resort: signed integer.
        DefinedBits = DefinedBits or 32
        local ContextString = `Number(Int{DefinedBits})`

        return {
            _Serialize = function(Buffer, Value, _Context)
                local BufferContext = Buffer.Context

                if (BufferContext) then
                    BufferContext(ContextString)
                end

                Buffer.WriteInt(DefinedBits, Value)

                if (BufferContext) then
                    BufferContext()
                end
            end;
            _Deserialize = function(Buffer, _Context)
                return Buffer.ReadInt(DefinedBits)
            end;
        }
    end
    --#endregion

    -- Resort to: double.
    return MysteriousNumber
end

NumberClass.InitialConstraint = NumberClass.RangeInclusive
return Number