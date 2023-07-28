local function anyfn(...) return ({} :: any) end
it = it or anyfn
expect = expect or anyfn
describe = describe or anyfn

return function()
    local TypeGuard = require(script.Parent.Parent)

    it("should reject nil values", function()
        expect(TypeGuard.Any():Check(nil)).to.equal(false)
    end)

    it("should accept any non-nil type", function()
        expect(TypeGuard.Any():Check(1)).to.equal(true)
        expect(TypeGuard.Any():Check("Test")).to.equal(true)
        expect(TypeGuard.Any():Check(function() end)).to.equal(true)
        expect(TypeGuard.Any():Check({})).to.equal(true)
        expect(TypeGuard.Any():Check(false)).to.equal(true)
    end)
end