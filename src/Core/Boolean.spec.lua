local function anyfn(...) return ({} :: any) end
it = it or anyfn
expect = expect or anyfn
describe = describe or anyfn

return function()
    local GetValues = require(script.Parent._TestValues)
    local TypeGuard = require(script.Parent.Parent)
    local Base = TypeGuard.Boolean()

    describe("Init", function()
        it("should reject non-booleans", function()
            for _, Value in GetValues("Boolean") do
                expect(Base:Check(Value)).to.equal(false)
            end
        end)

        it("should accept booleans", function()
            expect(Base:Check(false)).to.equal(true)
            expect(Base:Check(true)).to.equal(true)
        end)
    end)

    describe("Serialize, Deserialize", function()
        it("should correctly serialize & deserialize booleans", function()
            expect(Base:Deserialize(Base:Serialize(false))).to.equal(false)
            expect(Base:Deserialize(Base:Serialize(true))).to.equal(true)
        end)
    end)
end