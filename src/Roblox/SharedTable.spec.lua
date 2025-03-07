local function anyfn(...) return ({} :: any) end
it = it or anyfn
expect = expect or anyfn
describe = describe or anyfn

return function()
    local DeepEquals = require(script.Parent.Parent.Core._Equals)
    local GetValues = require(script.Parent.Parent.Core._TestValues)
    local TypeGuard = require(script.Parent.Parent)
    local Base = TypeGuard.SharedTable()

    describe("Init", function()
        it("should reject non-SharedTables", function()
            for _, Value in GetValues("SharedTable") do
                expect(Base:Check(Value)).to.equal(false)
            end
        end)

        it("should accept SharedTables", function()
            expect(Base:Check(SharedTable.new())).to.equal(true)
        end)
    end)

    describe("Serialize, Deserialize", function()
        it("should correctly serialize & deserialize SharedTable", function()
            local Test1 = SharedTable.new()
            local Test2 = SharedTable.new({X = 1, Y = "2"})
            local Deserialized1 = Base:Deserialize(Base:Serialize(Test1))
            local Deserialized2 = Base:Deserialize(Base:Serialize(Test2))

            expect(typeof(Deserialized1) == "SharedTable").to.equal(true)

            for _ in Deserialized1 do
                error("Deserialized1 has values")
            end

            expect(typeof(Deserialized2) == "SharedTable").to.equal(true)

            local Count = 0

            for _ in Deserialized2 do
                Count += 1
            end

            expect(Count).to.equal(2)
            expect(Deserialized2.X).to.equal(1)
            expect(Deserialized2.Y).to.equal("2")
        end)
    end)
end