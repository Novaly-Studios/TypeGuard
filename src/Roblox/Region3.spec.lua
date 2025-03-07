local function anyfn(...) return ({} :: any) end
it = it or anyfn
expect = expect or anyfn
describe = describe or anyfn

return function()
    local GetValues = require(script.Parent.Parent.Core._TestValues)
    local TypeGuard = require(script.Parent.Parent)
    local Base = TypeGuard.Region3()

    describe("Init", function()
        it("should reject non-Region3s", function()
            for _, Value in GetValues("Region3") do
                expect(Base:Check(Value)).to.equal(false)
            end
        end)

        it("should accept Region3s", function()
            expect(Base:Check(Region3.new(Vector3.new(10, 10, 10), Vector3.new(20, 20, 20)))).to.equal(true)
        end)
    end)

    describe("Serialize, Deserialize", function()
        it("should corectly serialize & deserialize Region3s", function()
            local Test = Region3.new(Vector3.new(10, 10, 10), Vector3.new(20, 20, 20))
            expect(Base:Deserialize(Base:Serialize(Test))).to.equal(Test)
        end)
    end)
end