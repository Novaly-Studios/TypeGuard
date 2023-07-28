local function anyfn(...) return ({} :: any) end
it = it or anyfn
expect = expect or anyfn
describe = describe or anyfn

return function()
    local TypeGuard = require(script.Parent.Parent)
    local Base = TypeGuard.Boolean()

    describe("Init", function()
        it("should reject non-booleans", function()
            expect(Base:Check("Test")).to.equal(false)
            expect(Base:Check(1)).to.equal(false)
            expect(Base:Check(function() end)).to.equal(false)
            expect(Base:Check(nil)).to.equal(false)
            expect(Base:Check({})).to.equal(false)
        end)

        it("should accept booleans", function()
            expect(Base:Check(true)).to.equal(true)
            expect(Base:Check(false)).to.equal(true)
        end)
    end)
end