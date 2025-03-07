local function anyfn(...) return ({} :: any) end
it = it or anyfn
expect = expect or anyfn
describe = describe or anyfn

return function()
    local GetValues = require(script.Parent.Parent.Core._TestValues)
    local TypeGuard = require(script.Parent.Parent)
    local Base = TypeGuard.BrickColor()

    describe("Init", function()
        it("should reject non-BrickColors", function()
            for _, Value in GetValues("BrickColor") do
                expect(Base:Check(Value)).to.equal(false)
            end
        end)

        it("should accept BrickColors", function()
            expect(Base:Check(BrickColor.Green())).to.equal(true)
        end)
    end)

    describe("Serialize, Deserialize", function()
        it("should correctly serialize & deserialize Color3s", function()
            local Test = BrickColor.Blue()
            expect(Base:Deserialize(Base:Serialize(Test))).to.equal(Test)
        end)
    end)
end