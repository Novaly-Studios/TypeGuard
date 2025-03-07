local function anyfn(...) return ({} :: any) end
it = it or anyfn
expect = expect or anyfn
describe = describe or anyfn

return function()
    local GetValues = require(script.Parent.Parent.Core._TestValues)
    local TypeGuard = require(script.Parent.Parent)
    local Base = TypeGuard.OverlapParams()

    describe("Init", function()
        it("should reject non-OverlapParams", function()
            for _, Value in GetValues("OverlapParams") do
                expect(Base:Check(Value)).to.equal(false)
            end
        end)

        it("should accept OverlapParams", function()
            expect(Base:Check(OverlapParams.new())).to.equal(true)
        end)
    end)

    describe("Serialize, Deserialize", function()
        it("should correctly serialize & deserialize OverlapParams", function()
            local Test = OverlapParams.new()
            Test.MaxParts = 100
            Test.RespectCanCollide = true
            Test.CollisionGroup = "AHHH"
            expect(Base:Deserialize(Base:Serialize(Test))).to.equal(Test)
        end)
    end)
end