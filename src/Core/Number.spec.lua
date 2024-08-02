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
            for _, Value in GetValues("Number") do
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
                local Checker = Base:Integer(Bits)
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

        it("should reject larger than 32 bits", function()
            expect(function()
                Base:Integer(33):Check(1)
            end).to.throw()
            expect(function()
                Base:Integer(33, true):Check(1)
            end).to.throw()
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

    describe("GreaterThan", function()
        it("should reject numbers less than the first arg", function()
            expect(Base:GreaterThan(1):Check(0)).to.equal(false)
            expect(Base:GreaterThan(function()
                return 1
            end):Check(1)).to.equal(false)
        end)

        it("should accept numbers greater than the first arg", function()
            expect(Base:GreaterThan(1):Check(2)).to.equal(true)
            expect(Base:GreaterThan(function()
                return 1
            end):Check(2)).to.equal(true)
        end)
    end)

    describe("IsNaN", function()
        it("should reject normal numbers", function()
            expect(Base:IsNaN():Check(1)).to.equal(false)
        end)

        it("should accept NaN", function()
            expect(Base:IsNaN():Check(math.sqrt(-1))).to.equal(true)
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