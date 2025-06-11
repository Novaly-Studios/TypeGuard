local function anyfn(...) return ({} :: any) end
it = it or anyfn
expect = expect or anyfn
describe = describe or anyfn

return function()
    local DeepEquals = require(script.Parent._Equals)
    local TypeGuard = require(script.Parent.Parent)
    local CacheableString = TypeGuard.Cacheable(TypeGuard.String())
    local Array = TypeGuard.Array(TypeGuard.Object(CacheableString, CacheableString))
    local ValueCache = TypeGuard.ValueCache(Array)
    local Test = table.create(100, {RepeatedField = "RepeatedField"})

    describe("Using", function()
        it("should serialize a repeated field table smaller than the captured sub-serializer", function()
            local Serialized1 = ValueCache:Serialize(Test)
            local Serialized2 = Array:Serialize(Test)
            expect(buffer.len(Serialized1) < buffer.len(Serialized2)).to.equal(true)
        end)

        it("should deserialize correctly", function()
            expect(DeepEquals(ValueCache:Deserialize(ValueCache:Serialize(Test)), Test)).to.equal(true)
        end)
    end)
end