local function anyfn(...) return ({} :: any) end
it = it or anyfn
expect = expect or anyfn
describe = describe or anyfn

return function()
    local GetValues = require(script.Parent.Parent.Core._TestValues)
    local TypeGuard = require(script.Parent.Parent)
    local Base = TypeGuard.FloatCurveKey()

    describe("Init", function()
        it("should reject non-FloatCurveKeys", function()
            for _, Value in GetValues("FloatCurveKey") do
                expect(Base:Check(Value)).to.equal(false)
            end
        end)

        it("should accept FloatCurveKeys", function()
            expect(Base:Check(FloatCurveKey.new(1, 2, Enum.KeyInterpolationMode.Cubic))).to.equal(true)
        end)
    end)

    describe("Serialize, Deserialize", function()
        it("should correctly serialize & deserialize FloatCurveKeys", function()
            local Test = FloatCurveKey.new(1, 2, Enum.KeyInterpolationMode.Cubic)
            expect(Base:Deserialize(Base:Serialize(Test))).to.equal(Test)
        end)
    end)
end