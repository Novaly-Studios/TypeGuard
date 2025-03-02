local function anyfn(...) return ({} :: any) end
it = it or anyfn
expect = expect or anyfn
describe = describe or anyfn

return function()
    local GetValues = require(script.Parent._TestValues)
    local TypeGuard = require(script.Parent.Parent)
    local Base = TypeGuard.Number()

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

        it("should serialize and deserialize a variety of numbers", function()
            expect(Base:Deserialize(Base:Serialize(1000))).to.equal(1000)
            expect(Base:Deserialize(Base:Serialize((2^50+0.35)))).to.equal((2^50+0.35))
            expect(Base:Deserialize(Base:Serialize((2^20+0.35)))).to.equal((2^20+0.35))
            expect(Base:Deserialize(Base:Serialize(0))).to.equal(0)
            expect(Base:Deserialize(Base:Serialize(-1000))).to.equal(-1000)
            expect(Base:Deserialize(Base:Serialize(-(2^50+0.35)))).to.equal(-(2^50+0.35))
            expect(Base:Deserialize(Base:Serialize(-(2^20+0.35)))).to.equal(-(2^20+0.35))
            expect(Base:Deserialize(Base:Serialize(math.huge))).to.equal(math.huge)
            expect(Base:Deserialize(Base:Serialize(-math.huge))).to.equal(-math.huge)
            expect(tostring(Base:Deserialize(Base:Serialize(0/0)))).to.equal(tostring(0/0))
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

        it("should bound to the correct ranges for unsigned ints", function()
            local Min = 0
            for Bits = 1, 32 do
                local Max = 2 ^ Bits - 1
                local Checker = Base:Integer(Bits, false)
                expect(Checker:Check(Max)).to.equal(true)
                expect(Checker:Check(Min)).to.equal(true)
                expect(Checker:Check(Max + 1)).to.equal(false)
                expect(Checker:Check(Min - 1)).to.equal(false)
            end
        end)

        it("should bound to the correct ranges for signed ints", function()
            for Bits = 2, 32 do
                local Max = 2 ^ (Bits - 1) - 1
                local Min = -2 ^ (Bits - 1)
                local Checker = Base:Integer(Bits, true)
                expect(Checker:Check(Max)).to.equal(true)
                expect(Checker:Check(Min)).to.equal(true)
                expect(Checker:Check(Max + 1)).to.equal(false)
                expect(Checker:Check(Min - 1)).to.equal(false)
            end
        end)

        it("should serialize and deserialize various integers", function()
            local Int32 = Base:Integer(32)
            expect(Int32:Deserialize(Int32:Serialize(2^31-1))).to.equal(2^31-1)
            expect(Int32:Deserialize(Int32:Serialize(-2^31))).to.equal(-2^31)

            local UInt32 = Base:Integer(32, false)
            expect(UInt32:Deserialize(UInt32:Serialize(2^32-1))).to.equal(2^32-1)
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

        it("should serialize and deserialize various decimals", function()
            local Decimal = Base:Decimal()
            expect(Decimal:Deserialize(Decimal:Serialize(100.5))).to.equal(100.5)
            expect(Decimal:Deserialize(Decimal:Serialize((2^50)+0.5))).to.equal((2^50)+0.5)
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

        it("should serialize and deserialize", function()
            local Int = Base:Integer():RangeInclusive(0, 100)
            expect(Int:Deserialize(Int:Serialize(0))).to.equal(0)
            expect(Int:Deserialize(Int:Serialize(50))).to.equal(50)
            expect(Int:Deserialize(Int:Serialize(100))).to.equal(100)

            local Float = Base:RangeInclusive(0, 100)
            expect(Float:Deserialize(Float:Serialize(0))).to.equal(0)
            expect(Float:Deserialize(Float:Serialize(50.5))).to.equal(50.5)
            expect(Float:Deserialize(Float:Serialize(100))).to.equal(100)
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

        it("should serialize and deserialize", function()
            local Int = Base:Integer():RangeExclusive(0, 100)
            expect(Int:Deserialize(Int:Serialize(1))).to.equal(1)
            expect(Int:Deserialize(Int:Serialize(50))).to.equal(50)
            expect(Int:Deserialize(Int:Serialize(99))).to.equal(99)

            local Float = Base:RangeExclusive(0, 100)
            expect(Float:Deserialize(Float:Serialize(0.01))).to.equal(0.01)
            expect(Float:Deserialize(Float:Serialize(50.123))).to.equal(50.123)
            expect(Float:Deserialize(Float:Serialize(99.99))).to.equal(99.99)
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

        it("should serialize and deserialize", function()
            local UInt = Base:Integer():Positive()
            expect(UInt:Deserialize(UInt:Serialize(10))).to.equal(10)
            expect(UInt:Deserialize(UInt:Serialize(2^32-1))).to.equal(2^32-1)
            expect(UInt:Deserialize(UInt:Serialize(2^50))).to.equal(2^50)

            local Float = Base:Positive()
            expect(Float:Deserialize(Float:Serialize(10))).to.equal(10)
            expect(Float:Deserialize(Float:Serialize(10.5))).to.equal(10.5)
            expect(Float:Deserialize(Float:Serialize(2^50+0.5))).to.equal(2^50+0.5)
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

        it("should serialize and deserialize", function()
            local UInt = Base:Integer():Negative()
            expect(UInt:Deserialize(UInt:Serialize(-10))).to.equal(-10)
            expect(UInt:Deserialize(UInt:Serialize(-2^32-1))).to.equal(-2^32-1)
            expect(UInt:Deserialize(UInt:Serialize(-2^50))).to.equal(-2^50)

            local Float = Base:Negative()
            expect(Float:Deserialize(Float:Serialize(-10))).to.equal(-10)
            expect(Float:Deserialize(Float:Serialize(-10.123))).to.equal(-10.123)
            expect(Float:Deserialize(Float:Serialize(-2^50+0.123))).to.equal(-2^50+0.123)
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

        it("should serialize and deserialize", function()
            local Close = Base:IsClose(0.5, 0.1)
            expect(Close:Deserialize(Close:Serialize(0.4))).to.equal(0.4)
            expect(Close:Deserialize(Close:Serialize(0.5))).to.equal(0.5)
            expect(Close:Deserialize(Close:Serialize(0.6))).to.equal(0.6)
        end)
    end)

    describe("Dynamic", function()
        it("should serialize and deserialize", function()
            local DynamicInt = Base:Integer(32):Dynamic()
            local Sample1 = DynamicInt:Serialize(2^31-1, "Bit")
            expect(buffer.len(Sample1)).to.equal(5)
            local Sample2 = DynamicInt:Serialize(-2^31, "Bit")
            expect(buffer.len(Sample2)).to.equal(5)
            local Sample3 = DynamicInt:Serialize(2^24-1, "Bit")
            expect(buffer.len(Sample3)).to.equal(4)
            local Sample4 = DynamicInt:Serialize(-2^24-1, "Bit")
            expect(buffer.len(Sample4)).to.equal(4)
            local Sample5 = DynamicInt:Serialize(2^16-1, "Bit")
            expect(buffer.len(Sample5)).to.equal(3)
            local Sample6 = DynamicInt:Serialize(-2^16-1, "Bit")
            expect(buffer.len(Sample6)).to.equal(3)
            local Sample7 = DynamicInt:Serialize(2^8-1, "Bit")
            expect(buffer.len(Sample7)).to.equal(2)
            local Sample8 = DynamicInt:Serialize(-2^8-1, "Bit")
            expect(buffer.len(Sample8)).to.equal(2)
        end)
    end)
end