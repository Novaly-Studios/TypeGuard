local function anyfn(...) return ({} :: any) end
it = it or anyfn
expect = expect or anyfn
describe = describe or anyfn

return function()
    local GetValues = require(script.Parent._TestValues)
    local TypeGuard = require(script.Parent.Parent)
    local Base = TypeGuard.Nil()

    describe("Init", function()
        it("should reject non-nil values", function()
            for _, Value in GetValues() do
                expect(Base:Check(Value)).to.equal(false)
            end
        end)

        it("should accept nil", function()
            expect(Base:Check(nil)).to.equal(true)
        end)

        it("should correctly serialize & deserialize", function()
            expect(Base:Deserialize(Base:Serialize(nil))).to.equal(nil)
        end)
    end)
end