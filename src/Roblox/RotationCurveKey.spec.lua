local function anyfn(...) return ({} :: any) end
it = it or anyfn
expect = expect or anyfn
describe = describe or anyfn

return function()
    local GetValues = require(script.Parent.Parent.Core._TestValues)
    local TypeGuard = require(script.Parent.Parent)
    local Base = TypeGuard.RotationCurveKey()

    describe("Init", function()
        it("should reject non-RotationCurveKeys", function()
            for _, Value in GetValues("RotationCurveKey") do
                expect(Base:Check(Value)).to.equal(false)
            end
        end)

        it("should accept RotationCurveKeys", function()
            expect(Base:Check(RotationCurveKey.new(1.5, CFrame.new(1, 2, 3), Enum.KeyInterpolationMode.Cubic))).to.equal(true)
        end)
    end)

    describe("Serialize, Deserialize", function()
        it("should correctly serialize & deserialize RotationCurveKeys", function()
            local Test = RotationCurveKey.new(1.5, CFrame.new(1, 2, 3), Enum.KeyInterpolationMode.Cubic)
            expect(Base:Deserialize(Base:Serialize(Test))).to.equal(Test)
        end)
    end)
end