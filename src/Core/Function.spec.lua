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
end