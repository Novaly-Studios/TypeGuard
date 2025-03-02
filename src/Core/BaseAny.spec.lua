local function anyfn(...) return ({} :: any) end
it = it or anyfn
expect = expect or anyfn
describe = describe or anyfn

return function()
    local DeepEquals = require(script.Parent._Equals)
    local GetValues = require(script.Parent._TestValues)
    local TypeGuard = require(script.Parent.Parent)
    local Base = TypeGuard.BaseAny

    describe("Init", function()
        it(`should accept all known Luau types`, function()
            for ID, Value in GetValues("Rbx") do
                expect(Base:Check(Value)).to.equal(true)
            end
        end)
    end)

    describe("Serialize, Deserialize", function()
        it("should serialize non-thread, non-function values", function()
            for ID, Value in GetValues("Rbx", "Function", "Thread") do
                local Serialized = Base:Serialize(Value)
                expect(Serialized).to.be.ok()
                local Deserialized = Base:Deserialize(Serialized)
                expect(DeepEquals(Value, Deserialized)).to.equal(true)
            end
        end)
    end)
end