local function anyfn(...) return ({} :: any) end
it = it or anyfn
expect = expect or anyfn
describe = describe or anyfn

return function()
    local TypeGuard = require(script.Parent.Parent)
    local Base = TypeGuard.Number()

    describe("Init", function()
        it("should reject non-numbers", function()
            expect(Base:Check("Test")).to.equal(false)
            expect(Base:Check(true)).to.equal(false)
            expect(Base:Check(function() end)).to.equal(false)
            expect(Base:Check(nil)).to.equal(false)
            expect(Base:Check({})).to.equal(false)
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

    describe("Equals", function()
        it("should reject non equal inputs", function()
            expect(Base:Equals(1):Check(2)).to.equal(false)
            expect(Base:Equals(function()
                return 1
            end):Check(2)).to.equal(false)
        end)

        it("should accept equal inputs", function()
            expect(Base:Equals(1):Check(1)).to.equal(true)
            expect(Base:Equals(function()
                return 1
            end):Check(1)).to.equal(true)
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

    describe("IsAKeyIn", function()
        it("should reject a non table as first arg", function()
            expect(function()
                Base:IsAKeyIn(1)
            end).to.throw()

            expect(function()
                Base:IsAKeyIn("Test")
            end).to.throw()

            expect(function()
                Base:IsAKeyIn(true)
            end).to.throw()
        end)

        it("should accept a table or function as first arg", function()
            expect(function()
                Base:IsAKeyIn({})
            end).never.to.throw()

            expect(function()
                Base:IsAKeyIn(function() end)
            end).never.to.throw()
        end)

        it("should reject when the value does not exist as a key", function()
            expect(Base:IsAKeyIn({}):Check(123)).to.equal(false)
            expect(Base:IsAKeyIn(function()
                return {}
            end):Check(123)).to.equal(false)
        end)

        it("should accept when the value does exist as a key", function()
            expect(Base:IsAKeyIn({[123] = true}):Check(123)).to.equal(true)
            expect(Base:IsAKeyIn(function()
                return {[123] = true}
            end):Check(123)).to.equal(true)
        end)
    end)

    describe("IsAValueIn", function()
        it("should reject a non table as first arg", function()
            expect(function()
                Base:IsAValueIn(1)
            end).to.throw()

            expect(function()
                Base:IsAValueIn("Test")
            end).to.throw()

            expect(function()
                Base:IsAValueIn(true)
            end).to.throw()
        end)

        it("should accept a table or function as first arg", function()
            expect(function()
                Base:IsAValueIn({})
            end).never.to.throw()

            expect(function()
                Base:IsAValueIn(function() end)
            end).never.to.throw()
        end)

        it("should reject when the value does not exist in an array", function()
            expect(Base:IsAValueIn({}):Check(123)).to.equal(false)
            expect(Base:IsAValueIn(function()
                return {}
            end):Check(123)).to.equal(false)
        end)

        it("should accept when the value exists in an array", function()
            expect(Base:IsAValueIn({123}):Check(123)).to.equal(true)
            expect(Base:IsAValueIn(function()
                return {123}
            end):Check(123)).to.equal(true)
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