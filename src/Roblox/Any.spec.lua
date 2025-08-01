local function anyfn(...) return ({} :: any) end
it = it or anyfn
expect = expect or anyfn
describe = describe or anyfn

return function()
    local DeepEquals = require(script.Parent.Parent.Core._Equals)
    local GetValues = require(script.Parent.Parent.Core._TestValues)
    local TypeGuard = require(script.Parent.Parent)
    local Base = TypeGuard.Any()

    describe("Init", function()
        it(`should accept all known Luau and Roblox types`, function()
            for ID, Value in GetValues() do
                expect(Base:Check(Value)).to.equal(true)
            end
        end)
    end)

    describe("Serialize, Deserialize", function()
        it("should serialize non-thread, non-function, non-Instance, non-userdata values", function()
            for ID, Value in GetValues("Function", "Thread", "Instance", "Userdata") do
                --[[ print("The", ID, Value, Base:Deserialize(Base:Serialize(Value))) ]]
                local Serialized = Base:Serialize(Value)
                expect(Serialized).to.be.ok()
                local Deserialized = Base:Deserialize(Serialized)
                expect(DeepEquals(Value, Deserialized)).to.equal(true)
            end
        end)
    end)
end