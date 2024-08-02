local function anyfn(...) return ({} :: any) end
it = it or anyfn
expect = expect or anyfn
describe = describe or anyfn

return function()
    local GetValues = require(script.Parent.Parent.Core._TestValues)
    local TypeGuard = require(script.Parent.Parent)
    local Base = TypeGuard.BaseAny(1)

    describe("Init", function()
        it(`should accept all values`, function()
            for ID, Value in GetValues() do
                expect(Base:Check(Value)).to.equal(true)
            end
        end)
    end)

    describe("Serialize, Deserialize", function()
        it("should serialize non-thread, non-function values", function()
            for ID, Value in GetValues("Function", "Thread") do
                expect(Base:Serialize(Value)).to.be.ok()
            end
        end)
    end)
end