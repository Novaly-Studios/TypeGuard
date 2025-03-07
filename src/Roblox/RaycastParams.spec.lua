local function anyfn(...) return ({} :: any) end
it = it or anyfn
expect = expect or anyfn
describe = describe or anyfn

return function()
    local GetValues = require(script.Parent.Parent.Core._TestValues)
    local TypeGuard = require(script.Parent.Parent)
    local Base = TypeGuard.RaycastParams()

    describe("Init", function()
        it("should reject non-RaycastParams", function()
            for _, Value in GetValues("RaycastParams") do
                expect(Base:Check(Value)).to.equal(false)
            end
        end)

        it("should accept RaycastParams", function()
            expect(Base:Check(RaycastParams.new())).to.equal(true)
        end)
    end)

    describe("Serialize, Deserialize", function()
        it("should correctly serialize & deserialize RaycastParams", function()
            local Test = RaycastParams.new()
            Test.RespectCanCollide = true
            Test.CollisionGroup = "AHHH"
            Test.IgnoreWater = true
            expect(Base:Deserialize(Base:Serialize(Test))).to.equal(Test)
        end)
    end)
end