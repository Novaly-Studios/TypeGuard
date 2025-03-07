local function anyfn(...) return ({} :: any) end
it = it or anyfn
expect = expect or anyfn
describe = describe or anyfn

return function()
    local GetValues = require(script.Parent.Parent.Core._TestValues)
    local TypeGuard = require(script.Parent.Parent)
    local Base = TypeGuard.PhysicalProperties()

    describe("Init", function()
        it("should reject non-PhysicalProperties", function()
            for _, Value in GetValues("PhysicalProperties") do
                expect(Base:Check(Value)).to.equal(false)
            end
        end)

        it("should accept PhysicalProperties", function()
            expect(Base:Check(PhysicalProperties.new(Enum.Material.Sandstone))).to.equal(true)
        end)
    end)

    describe("Serialize, Deserialize", function()
        it("should correctly serialize & deserialize PhysicalProperties", function()
            local Test = PhysicalProperties.new(Enum.Material.Sandstone)
            expect(Base:Deserialize(Base:Serialize(Test))).to.equal(Test)
        end)
    end)
end