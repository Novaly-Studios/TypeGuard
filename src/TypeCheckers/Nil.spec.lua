local function anyfn(...) return ({} :: any) end
it = it or anyfn
expect = expect or anyfn
describe = describe or anyfn

return function()
    local TypeGuard = require(script.Parent.Parent)

    describe("Init", function()
        it("should accept nil", function()
            expect(TypeGuard.Nil():Check(nil)).to.equal(true)
        end)

        it("should reject non-nil", function()
            expect(TypeGuard.Nil():Check(1)).to.equal(false)
            expect(TypeGuard.Nil():Check(function() end)).to.equal(false)
            expect(TypeGuard.Nil():Check({})).to.equal(false)
            expect(TypeGuard.Nil():Check(false)).to.equal(false)
        end)
    end)
end