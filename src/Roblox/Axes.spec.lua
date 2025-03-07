local function anyfn(...) return ({} :: any) end
it = it or anyfn
expect = expect or anyfn
describe = describe or anyfn

return function()
    local GetValues = require(script.Parent.Parent.Core._TestValues)
    local TypeGuard = require(script.Parent.Parent)
    local Base = TypeGuard.Axes()

    describe("Init", function()
        it("should reject non-Axes", function()
            for _, Value in GetValues("Axes") do
                expect(Base:Check(Value)).to.equal(false)
            end
        end)

        it("should accept Axes", function()
            expect(Base:Check(Axes.new(Enum.NormalId.Top))).to.equal(true)
        end)
    end)

    describe("Serialize, Deserialize", function()
        it("should correctly serialize & deserialize Color3s", function()
            local Test = Axes.new(Enum.NormalId.Top, Enum.NormalId.Left)
            expect(Base:Deserialize(Base:Serialize(Test))).to.equal(Test)
        end)
    end)
end