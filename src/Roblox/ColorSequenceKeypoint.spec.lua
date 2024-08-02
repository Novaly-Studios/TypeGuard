local function anyfn(...) return ({} :: any) end
it = it or anyfn
expect = expect or anyfn
describe = describe or anyfn

return function()
    local GetValues = require(script.Parent.Parent.Core._TestValues)
    local TypeGuard = require(script.Parent.Parent)
    local Base = TypeGuard.ColorSequenceKeypoint()

    describe("Init", function()
        it("should reject non-ColorSequenceKeypoints", function()
            for _, Value in GetValues("ColorSequenceKeypoint") do
                expect(Base:Check(Value)).to.equal(false)
            end
        end)

        it("should accept ColorSequenceKeypoints", function()
            expect(Base:Check(ColorSequenceKeypoint.new(1, Color3.new(1, 1, 1)))).to.equal(true)
        end)
    end)

    describe("Serialize, Deserialize", function()
        it("should correctly serialize & deserialize ColorSequenceKeypoints", function()
            local Test = ColorSequenceKeypoint.new(1, Color3.new(1, 1, 1))
            expect(Base:Deserialize(Base:Serialize(Test))).to.equal(Test)
        end)
    end)
end