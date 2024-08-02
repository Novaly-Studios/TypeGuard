local function anyfn(...) return ({} :: any) end
it = it or anyfn
expect = expect or anyfn
describe = describe or anyfn

return function()
    local GetValues = require(script.Parent.Parent.Core._TestValues)
    local TypeGuard = require(script.Parent.Parent)
    local Base = TypeGuard.Ray()

    describe("Init", function()
        it("should reject non-Rays", function()
            for _, Value in GetValues("Ray") do
                expect(Base:Check(Value)).to.equal(false)
            end
        end)

        it("should accept Rays", function()
            expect(Base:Check(Ray.new(Vector3.zero, Vector3.one))).to.equal(true)
        end)
    end)

    describe("Serialize, Deserialize", function()
        it("should correctly serialize & deserialize Rays", function()
            local Test = Ray.new(Vector3.new(100, 100, -100), Vector3.one)
            expect(Base:Deserialize(Base:Serialize(Test))).to.equal(Test)
        end)
    end)
end