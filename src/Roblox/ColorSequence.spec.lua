local function anyfn(...) return ({} :: any) end
it = it or anyfn
expect = expect or anyfn
describe = describe or anyfn

return function()
    local GetValues = require(script.Parent.Parent.Core._TestValues)
    local TypeGuard = require(script.Parent.Parent)
    local Base = TypeGuard.ColorSequence()

    describe("Init", function()
        it("should reject non-ColorSequences", function()
            for _, Value in GetValues("ColorSequence") do
                expect(Base:Check(Value)).to.equal(false)
            end
        end)

        it("should accept ColorSequences", function()
            expect(Base:Check(ColorSequence.new(Color3.new(0, 0, 0), Color3.new(0.5, 0.5, 0.5)))).to.equal(true)
        end)
    end)

    describe("Serialize, Deserialize", function()
        it("should correctly serialize & deserialize ColorSequences", function()
            local Test = ColorSequence.new(Color3.new(0, 0, 0), Color3.new(0.5, 0.5, 0.5))
            expect(Base:Deserialize(Base:Serialize(Test))).to.equal(Test)
        end)
    end)
end