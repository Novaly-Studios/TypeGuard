local function anyfn(...) return ({} :: any) end
it = it or anyfn
expect = expect or anyfn
describe = describe or anyfn

return function()
    local GetValues = require(script.Parent._TestValues)
    local TypeGuard = require(script.Parent.Parent)
    local Base = TypeGuard.Function()

    describe("Init", function()
        it("should reject non-functions", function()
            for _, Value in GetValues("Function") do
                expect(Base:Check(Value)).to.equal(false)
            end
        end)

        it("should accept functions", function()
            expect(Base:Check(function() end)).to.equal(true)
        end)
    end)

    describe("CheckParamCount", function()
        it("should reject functions whose param count does not satisfy the checker", function()
            local Checker = Base:CheckParamCount(TypeGuard.Number():LessThan(3))
            expect(Checker:Check(function() end)).to.equal(false)
        end)

        it("should accept functions whose param count does satisfy the checker", function()
            local Checker = Base:CheckParamCount(TypeGuard.Number():LessThan(3))
            expect(Checker:Check(function(X, Y, Z, W) end)).to.equal(true)
        end)
    end)
end