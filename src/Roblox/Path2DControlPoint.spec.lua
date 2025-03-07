local function anyfn(...) return ({} :: any) end
it = it or anyfn
expect = expect or anyfn
describe = describe or anyfn

return function()
    local GetValues = require(script.Parent.Parent.Core._TestValues)
    local TypeGuard = require(script.Parent.Parent)
    local Base = TypeGuard.Path2DControlPoint()

    describe("Init", function()
        it("should reject non-Path2DControlPoints", function()
            for _, Value in GetValues("Path2DControlPoint") do
                expect(Base:Check(Value)).to.equal(false)
            end
        end)

        it("should accept Path2DControlPoints", function()
            expect(Base:Check(Path2DControlPoint.new())).to.equal(true)
        end)
    end)

    describe("Serialize, Deserialize", function()
        it("should correctly serialize & deserialize Path2DControlPoints", function()
            local Test = Path2DControlPoint.new(UDim2.new(1, 1, 1, 1), UDim2.new(1, 1, 1, 1), UDim2.new(1, 1, 1, 1))
            expect(Base:Deserialize(Base:Serialize(Test))).to.equal(Test)
        end)
    end)
end