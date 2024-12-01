local function anyfn(...) return ({} :: any) end
it = it or anyfn
expect = expect or anyfn
describe = describe or anyfn

local function DeepEquals(X, Y)
    if (type(X) == "table" and type(Y) == "table") then
        for Key, Value in X do
            if (Y[Key] == nil) then
                return false
            end

            if (not DeepEquals(Value, Y[Key])) then
                return false
            end
        end

        for Key in Y do
            if (X[Key] == nil) then
                return false
            end
        end

        return true
    end

    return X == Y
end

return function()
    local GetValues = require(script.Parent._TestValues)
    local TypeGuard = require(script.Parent.Parent)
    local Base = TypeGuard.BaseAny(1)

    describe("Init", function()
        it(`should accept all Luau values`, function()
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
                expect(DeepEquals(Deserialized, Serialized)).to.equal(true)
            end
        end)
    end)
end