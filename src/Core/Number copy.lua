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

local function _Integer(_, Item)
    if (Item % 1 == 0) then
        return true
    end

    return false, `Expected integer form, got {Item}`
end

--- Checks if the value is whole.
function NumberClass:Integer(Bits, Signed)
    Signed = if (Signed == nil) then true else Signed
    Bits = Bits or 32

    if (Bits) then
        assert(Bits >= 1, "Integers must have at least 1 bit")
        assert(Bits <= 53, "Integers must have at most 53 bits")
    end

    self = self:_AddConstraint(true, "Integer", _Integer, Bits)
    return (Signed and self:RangeInclusive(-2 ^ (Bits - 1), 2 ^ (Bits - 1) - 1) or self:RangeInclusive(0, 2 ^ Bits - 1))
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
function NumberClass:Dynamic(Resolution: number?)
    return self:Modify({
        _Dynamic = Resolution or 1;
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

--- Checks if the number has a range fit for floats of the precision given.
function NumberClass:Float(Precision)
    ExpectType(Precision, Expect.NUMBER_OR_FUNCTION, 1)

    local MaxValue = Precision < 33 and FLOAT_MAX_32 or FLOAT_MAX_64
    return self:RangeInclusive(-MaxValue, MaxValue)
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

NumberClass.InitialConstraint = NumberClass.RangeInclusive

local NaN = 0 / 0
function NumberClass:_UpdateSerialize()
    local MysteriousNumber = { -- Default to double if we don't know many details about the number. Largest number type in Luau.
        _Serialize = function(Buffer, Value, _Context)
            local BufferContext = Buffer.Context
            BufferContext("Number")
            Buffer.WriteFloat(64, Value)
            BufferContext()
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
                BufferContext("Number(IsInfinite)")
                Buffer.WriteUInt(1, Value == math.huge and 1 or 0)
                BufferContext()
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
                BufferContext("Number(IsNaN)")
                BufferContext()
            end;
            _Deserialize = function(_, _)
                return NaN
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

    if (Integer) then
        if (Integer[1] <= 32) then -- No support for >32 bit ints yet, they will be serialized as floats.
            local Positive = self:GetConstraint("Positive")
            local Negative = self:GetConstraint("Negative")

            if (self._Dynamic) then
                if (Positive or Negative) then
                    local ContextString = (Negative and "Number(Dynamic, Integer, Negative)" or "Number(Dynamic, Integer, Positive)")

                    return {
                        _Serialize = function(Buffer, Value, _Context)
                            local BufferContext = Buffer.Context
                            BufferContext(ContextString)

                            Value = (Negative and -Value or Value)
                            local Bits = 32 - bit32.countlz(Value)
                            local WriteUInt = Buffer.WriteUInt
                            WriteUInt(6, Bits)
                            WriteUInt(Bits, Value)

                            BufferContext()
                        end;
                        _Deserialize = function(Buffer, _Context)
                            local ReadUInt = Buffer.ReadUInt
                            local Value = ReadUInt(ReadUInt(6))
                            return (Negative and -Value or Value)
                        end;
                    }
                end

                return {
                    _Serialize = function(Buffer, Value, _Context)
                        local BufferContext = Buffer.Context
                        BufferContext("Number(Dynamic, Integer)")

                        local Sign = (Value < 0)
                        Value = (Sign and -Value or Value)
                        local Bits = 32 - bit32.countlz(Value)
                        local Metadata = bit32.bor(Bits, Sign and 0b1000000 or 0)

                        local WriteUInt = Buffer.WriteUInt
                        WriteUInt(7, Metadata)
                        WriteUInt(Bits, Value)

                        BufferContext()
                    end;
                    _Deserialize = function(Buffer, _Context)
                        local ReadUInt = Buffer.ReadUInt
                        local Metadata = ReadUInt(6)
                        local Sign = (bit32.band(Metadata, 0b1000000) == 0)
                        local Bits = bit32.extract(Metadata, 0, 6)
                        local Value = ReadUInt(Bits)
                        return (Sign and Value or -Value)
                    end;
                }
            end

            -- The number of bits required to store the integer can be reduced if the range
            -- is known to be between two concrete values.
            if (Min and Max) then
                local Bits = math.log(math.abs(Max - Min), 2) // 1 + 1

                return {
                    _Serialize = function(Buffer, Value, _Context)
                        local BufferContext = Buffer.Context
                        BufferContext("Number(Integer, Min, Max)")
                        Buffer.WriteUInt(Bits, Value - Min)
                        BufferContext()
                    end;
                    _Deserialize = function(Buffer, _Context)
                        return Buffer.ReadUInt(Bits) + Min
                    end;
                }
            end

            if (Positive or Integer[2]) then
                return {
                    _Serialize = function(Buffer, Value, _Context)
                        local BufferContext = Buffer.Context
                        BufferContext("Number(Integer, Positive)")
                        Buffer.WriteUInt(32, Value)
                        BufferContext()
                    end;
                    _Deserialize = function(Buffer, _Context)
                        return Buffer.ReadUInt(32)
                    end;
                }
            end

            if (Negative) then
                return {
                    _Serialize = function(Buffer, Value, _Context)
                        local BufferContext = Buffer.Context
                        BufferContext("Number(Integer, Negative)")
                        Buffer.WriteUInt(32, -Value)
                        BufferContext()
                    end;
                    _Deserialize = function(Buffer, _Context)
                        return -Buffer.ReadUInt(32)
                    end;
                }
            end

            return {
                _Serialize = function(Buffer, Value, _Context)
                    local BufferContext = Buffer.Context
                    BufferContext("Number(Integer)")
                    Buffer.WriteInt(32, Value)
                    BufferContext()
                end;
                _Deserialize = function(Buffer, _Context)
                    return Buffer.ReadInt(32)
                end;
            }
        else
            return MysteriousNumber
        end
    end

    if (Min and Max) then
        if (Min >= -FLOAT_MAX_32 and Max <= FLOAT_MAX_32) then
            return {
                _Serialize = function(Buffer, Value, _Context)
                    local BufferContext = Buffer.Context
                    BufferContext("Number(Min, Max)")
                    Buffer.WriteFloat(32, Value)
                    BufferContext()
                end;
                _Deserialize = function(Buffer, _Context)
                    return Buffer.ReadFloat(32)
                end;
            }
        end
    end

    return MysteriousNumber
end

return Number