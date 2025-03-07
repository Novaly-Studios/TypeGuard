local function anyfn(...) return ({} :: any) end
it = it or anyfn
expect = expect or anyfn
describe = describe or anyfn

return function()
    local GetValues = require(script.Parent._TestValues)
    local TypeGuard = require(script.Parent.Parent)
    local Base = TypeGuard.Userdata()

    describe("Init", function()
        it("should reject non-userdata values", function()
            for _, Value in GetValues("Userdata") do
                expect(Base:Check(Value)).to.equal(false)
            end
        end)

        it("should accept userdata values", function()
            expect(Base:Check(newproxy(true))).to.equal(true)
        end)
    end)
end