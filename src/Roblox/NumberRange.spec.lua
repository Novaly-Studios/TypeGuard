local function anyfn(...) return ({} :: any) end
it = it or anyfn
expect = expect or anyfn
describe = describe or anyfn

return function()
    local GetValues = require(script.Parent.Parent.Core._TestValues)
    local TypeGuard = require(script.Parent.Parent)
    local Base = TypeGuard.NumberRange()

    describe("Init", function()
        it("should reject non-NumberRanges", function()
            for _, Value in GetValues("NumberRange") do
                expect(Base:Check(Value)).to.equal(false)
            end
        end)

        it("should accept NumberRanges", function()
            expect(Base:Check(NumberRange.new(0, 1))).to.equal(true)
        end)
    end)

    describe("Serialize, Deserialize", function()
        it("should correctly serialize & deserialize NumberRanges", function()
            local Test = NumberRange.new(1.25, 5.5)
            expect(Base:Deserialize(Base:Serialize(Test))).to.equal(Test)
        end)
    end)
end