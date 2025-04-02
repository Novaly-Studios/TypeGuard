local function anyfn(...) return ({} :: any) end
it = it or anyfn
expect = expect or anyfn
describe = describe or anyfn

return function()
    local GetValues = require(script.Parent._TestValues)
    local TypeGuard = require(script.Parent.Parent)
    local Base = TypeGuard.Number()

    --#region Pre-calculation of min and max values for different integer formats.
    local PositiveTable = {
        [0] = {
            Min = 0;
            Max = 0;
            TooLow = -1;
            TooHigh = 1;
        };
    }

    for Bits = 1, 32 do
        local Value = 2 ^ Bits - 1
        PositiveTable[Bits] = {
            Min = 0;
            Max = Value;
            TooLow = -1;
            TooHigh = Value + 1;
        }
    end

    local NegativeTable = {
        [0] = {
            Min = -1;
            Max = -1;
            TooLow = -2;
            TooHigh = 0;
        };
    }

    for Bits = 1, 32 do
        local Value = -2 ^ Bits
        NegativeTable[Bits] = {
            Min = -1;
            Max = Value;
            TooLow = Value - 1;
            TooHigh = 0;
        }
    end

    local PositiveNegativeTable = {
        [0] = {
            Max = 0;
            Min = 0;
            TooLow = -1;
            TooHigh = 1;
        };
    }

    for Bits = 1, 32 do
        local Less = Bits - 1
        PositiveNegativeTable[Bits] = {
            Min = -2 ^ Less;
            Max = 2 ^ Less - 1;
            TooLow = -2 ^ Less - 1;
            TooHigh = 2 ^ Less;
        }
    end
    --#endregion

    describe("Init", function()
        it("should reject non-numbers", function()
            for _, Value in GetValues("Number", "Float") do
                expect(Base:Check(Value)).to.equal(false)
            end
        end)

        it("should accept numbers", function()
            expect(Base:Check(1)).to.equal(true)
            expect(Base:Check(1.1)).to.equal(true)
            expect(Base:Check(0)).to.equal(true)
            expect(Base:Check(-1)).to.equal(true)
            expect(Base:Check(-1.1)).to.equal(true)
        end)
    end)

    describe("Default", function()
        it("should serialize and deserialize as a double", function()
            expect(Base:Deserialize(Base:Serialize(2^53))).to.equal(2^53)
        end)
    end)

    describe("Integer", function()
        it("should reject non-integers", function()
            expect(Base:Integer():Check(1.1)).to.equal(false)
        end)

        it("should accept integers", function()
            expect(Base:Integer():Check(1)).to.equal(true)
        end)

        it("should accept negative integers", function()
            expect(Base:Integer():Check(-1)).to.equal(true)
        end)

        it("should reject non-numbers", function()
            expect(Base:Integer():Check("Test")).to.equal(false)
        end)

        describe("Dynamic", function()
            local DynamicInt = Base:Integer():Dynamic()

            describe("Positive", function()
                local DynamicIntPositive = DynamicInt:Positive()

                it("should serialize and deserialize", function()
                    for Bits = 0, 32 do
                        local Thresholds = PositiveTable[Bits]
                        expect(DynamicIntPositive:Deserialize(DynamicIntPositive:Serialize(Thresholds.Max))).to.equal(Thresholds.Max)
                        expect(DynamicIntPositive:Deserialize(DynamicIntPositive:Serialize(Thresholds.Min))).to.equal(Thresholds.Min)
                    end
                end)

                it("should accept the correct range of values", function()
                    for Bits = 0, #PositiveTable do
                        local Thresholds = PositiveTable[Bits]
                        expect(DynamicIntPositive:Check(Thresholds.Min)).to.equal(true)
                        expect(DynamicIntPositive:Check(Thresholds.Max)).to.equal(true)
                    end

                    local Highest = PositiveTable[#PositiveTable]
                    expect(DynamicIntPositive:Check(Highest.TooLow)).to.equal(false)
                    expect(DynamicIntPositive:Check(Highest.TooHigh)).to.equal(false)
                end)
            end)

            describe("Negative", function()
                local DynamicIntNegative = DynamicInt:Negative()

                it("should accept the correct range of values", function()
                    for Bits = 0, #NegativeTable do
                        local Thresholds = NegativeTable[Bits]
                        expect(DynamicIntNegative:Check(Thresholds.Min)).to.equal(true)
                        expect(DynamicIntNegative:Check(Thresholds.Max)).to.equal(true)
                    end

                    local Highest = NegativeTable[#NegativeTable]
                    expect(DynamicIntNegative:Check(Highest.TooLow)).to.equal(false)
                    expect(DynamicIntNegative:Check(Highest.TooHigh)).to.equal(false)
                end)

                it("should serialize and deserialize", function()
                    for Bits = 0, #NegativeTable do
                        local Thresholds = NegativeTable[Bits]
                        expect(DynamicIntNegative:Deserialize(DynamicIntNegative:Serialize(Thresholds.Max))).to.equal(Thresholds.Max)
                        expect(DynamicIntNegative:Deserialize(DynamicIntNegative:Serialize(Thresholds.Min))).to.equal(Thresholds.Min)
                    end
                end)
            end)

            it("should accept the correct range of values", function()
                for Bits = 0, #NegativeTable do
                    local Thresholds = NegativeTable[Bits]
                    expect(DynamicInt:Check(Thresholds.Min)).to.equal(true)
                    expect(DynamicInt:Check(Thresholds.Max)).to.equal(true)
                end

                for Bits = 0, #PositiveTable do
                    local Thresholds = PositiveTable[Bits]
                    expect(DynamicInt:Check(Thresholds.Min)).to.equal(true)
                    expect(DynamicInt:Check(Thresholds.Max)).to.equal(true)
                end
            end)

            it("should serialize and deserialize", function()
                for Bits = 0, 32 do
                    local Thresholds = NegativeTable[Bits]
                    expect(DynamicInt:Deserialize(DynamicInt:Serialize(Thresholds.Max))).to.equal(Thresholds.Max)
                    expect(DynamicInt:Deserialize(DynamicInt:Serialize(Thresholds.Min))).to.equal(Thresholds.Min)
                end

                for Bits = 0, 32 do
                    local Thresholds = PositiveTable[Bits]
                    expect(DynamicInt:Deserialize(DynamicInt:Serialize(Thresholds.Max))).to.equal(Thresholds.Max)
                    expect(DynamicInt:Deserialize(DynamicInt:Serialize(Thresholds.Min))).to.equal(Thresholds.Min)
                end
            end)
        end)

        describe("Unsigned", function()
            it("should accept the correct range of values", function()
                for Bits = 0, 32 do
                    local UnsignedInt = Base:Integer(Bits, false)
                    local Thresholds = PositiveTable[Bits]
                    expect(UnsignedInt:Deserialize(UnsignedInt:Serialize(Thresholds.Max))).to.equal(Thresholds.Max)
                    expect(UnsignedInt:Deserialize(UnsignedInt:Serialize(Thresholds.Min))).to.equal(Thresholds.Min)
                end
            end)

            it("should serialize and deserialize", function()
                for Bits = 0, 32 do
                    local UnsignedInt = Base:Integer(Bits, false)
                    local Thresholds = PositiveTable[Bits]
                    expect(UnsignedInt:Deserialize(UnsignedInt:Serialize(Thresholds.Max))).to.equal(Thresholds.Max)
                    expect(UnsignedInt:Deserialize(UnsignedInt:Serialize(Thresholds.Min))).to.equal(Thresholds.Min)
                end
            end)
        end)

        describe("Signed", function()
            it("should accept the correct range of values", function()
                for Bits = 0, 32 do
                    local SignedInt = Base:Integer(Bits, true)
                    local Thresholds = PositiveNegativeTable[Bits]
                    expect(SignedInt:Deserialize(SignedInt:Serialize(Thresholds.Max))).to.equal(Thresholds.Max)
                    expect(SignedInt:Deserialize(SignedInt:Serialize(Thresholds.Min))).to.equal(Thresholds.Min)
                end
            end)

            it("should serialize and deserialize", function()
                for Bits = 0, 32 do
                    local SignedInt = Base:Integer(Bits, true)
                    local Thresholds = PositiveNegativeTable[Bits]
                    expect(SignedInt:Deserialize(SignedInt:Serialize(Thresholds.Max))).to.equal(Thresholds.Max)
                    expect(SignedInt:Deserialize(SignedInt:Serialize(Thresholds.Min))).to.equal(Thresholds.Min)
                end
            end)
        end)
    end)

    describe("Decimal", function()
        it("should reject non-decimals", function()
            expect(Base:Decimal():Check(1)).to.equal(false)
        end)

        it("should accept decimals", function()
            expect(Base:Decimal():Check(1.1)).to.equal(true)
        end)

        it("should accept negative decimals", function()
            expect(Base:Decimal():Check(-1.1)).to.equal(true)
        end)

        it("should reject non-numbers", function()
            expect(Base:Decimal():Check("Test")).to.equal(false)
        end)
    end)

    describe("RangeInclusive", function()
        it("should reject non-numbers", function()
            expect(Base:RangeInclusive(1, 2):Check("Test")).to.equal(false)
        end)

        it("should reject numbers outside of range", function()
            local Range = Base:RangeInclusive(1, 2)
            expect(Range:Check(0)).to.equal(false)
            expect(Range:Check(3)).to.equal(false)

            local FuncRange = Base:RangeInclusive(function()
                return 1
            end, function()
                return 2
            end)
            expect(FuncRange:Check(0)).to.equal(false)
            expect(FuncRange:Check(3)).to.equal(false)
        end)

        it("should accept numbers inside of range", function()
            local Range = Base:RangeInclusive(1, 2)
            expect(Range:Check(1)).to.equal(true)
            expect(Range:Check(2)).to.equal(true)

            local FuncRange = Base:RangeInclusive(function()
                return 1
            end, function()
                return 2
            end)
            expect(FuncRange:Check(2)).to.equal(true)
        end)

        it("should accept numbers equal to the range bounds", function()
            expect(Base:RangeInclusive(1, 2):Check(1)).to.equal(true)
            expect(Base:RangeInclusive(1, 2):Check(2)).to.equal(true)

            local FuncRange = Base:RangeInclusive(function()
                return 1
            end, function()
                return 2
            end)
            expect(FuncRange:Check(1)).to.equal(true)
            expect(FuncRange:Check(2)).to.equal(true)
        end)
    end)

    describe("RangeExclusive", function()
        it("should reject non-numbers", function()
            expect(Base:RangeExclusive(1, 2):Check("Test")).to.equal(false)
        end)

        it("should reject numbers outside of range", function()
            expect(Base:RangeExclusive(1, 2):Check(0)).to.equal(false)
            expect(Base:RangeExclusive(1, 2):Check(3)).to.equal(false)

            local FuncRange = Base:RangeExclusive(function()
                return 1
            end, function()
                return 2
            end)
            expect(FuncRange:Check(0)).to.equal(false)
            expect(FuncRange:Check(3)).to.equal(false)
        end)

        it("should accept numbers inside of range", function()
            expect(Base:RangeExclusive(1, 2):Check(1.1)).to.equal(true)
            expect(Base:RangeExclusive(1, 2):Check(1.9)).to.equal(true)

            local FuncRange = Base:RangeExclusive(function()
                return 1
            end, function()
                return 2
            end)
            expect(FuncRange:Check(1.1)).to.equal(true)
            expect(FuncRange:Check(1.9)).to.equal(true)
        end)

        it("should reject numbers equal to the range bounds", function()
            expect(Base:RangeExclusive(1, 2):Check(1)).to.equal(false)
            expect(Base:RangeExclusive(1, 2):Check(2)).to.equal(false)

            local FuncRange = Base:RangeExclusive(function()
                return 1
            end, function()
                return 2
            end)
            expect(FuncRange:Check(1)).to.equal(false)
            expect(FuncRange:Check(2)).to.equal(false)
        end)
    end)

    describe("Positive", function()
        it("should reject non-numbers", function()
            expect(Base:Positive():Check("Test")).to.equal(false)
        end)

        it("should reject negative numbers", function()
            expect(Base:Positive():Check(-1)).to.equal(false)
        end)

        it("should accept positive numbers", function()
            expect(Base:Positive():Check(0)).to.equal(true)
            expect(Base:Positive():Check(1)).to.equal(true)
        end)
    end)

    describe("Negative", function()
        it("should reject non-numbers", function()
            expect(Base:Negative():Check("Test")).to.equal(false)
        end)

        it("should reject positive numbers", function()
            expect(Base:Negative():Check(0)).to.equal(false)
            expect(Base:Negative():Check(1)).to.equal(false)
        end)

        it("should accept negative numbers", function()
            expect(Base:Negative():Check(-1)).to.equal(true)
        end)
    end)

    describe("IsNaN", function()
        it("should reject normal numbers", function()
            expect(Base:IsNaN():Check(1)).to.equal(false)
        end)

        it("should accept NaN", function()
            expect(Base:IsNaN():Check(math.sqrt(-1))).to.equal(true)
        end)

        it("should serialize and deserialize", function()
            local NaN = Base:IsNaN()
            expect(tostring(NaN:Deserialize(NaN:Serialize(0/0)))).to.equal(tostring(0/0))
        end)
    end)

    describe("IsInfinite", function()
        it("should reject finite numbers", function()
            expect(Base:IsInfinite():Check(1)).to.equal(false)
        end)

        it("should accept infinite numbers", function()
            expect(Base:IsInfinite():Check(math.huge)).to.equal(true)
            expect(Base:IsInfinite():Check(-math.huge)).to.equal(true)
        end)

        it("should serialize and deserialize", function()
            local Infinite = Base:IsInfinite()
            expect(Infinite:Deserialize(Infinite:Serialize(math.huge))).to.equal(math.huge)
            expect(Infinite:Deserialize(Infinite:Serialize(-math.huge))).to.equal(-math.huge)
        end)
    end)

    describe("IsClose", function()
        it("should reject non-numbers", function()
            expect(Base:IsClose(1):Check("Test")).to.equal(false)
        end)

        it("should reject numbers that are not close", function()
            expect(Base:IsClose(1):Check(2)).to.equal(false)
            expect(Base:IsClose(function()
                return 1
            end):Check(2)).to.equal(false)
        end)

        it("should accept numbers in the default tolerance (0.00001)", function()
            expect(Base:IsClose(1):Check(1 + 0.000001)).to.equal(true)
            expect(Base:IsClose(function()
                return 1
            end):Check(1 + 0.000001)).to.equal(true)
        end)

        it("should accept a custom tolerance", function()
            expect(Base:IsClose(1, 0.5):Check(1 + 0.4)).to.equal(true)
            expect(Base:IsClose(function()
                return 1
            end, 0.5):Check(1 + 0.4)).to.equal(true)
        end)
    end)
end