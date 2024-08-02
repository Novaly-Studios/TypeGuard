local function anyfn(...) return ({} :: any) end
it = it or anyfn
expect = expect or anyfn
describe = describe or anyfn

return function()
    local GetValues = require(script.Parent.Parent.Core._TestValues)
    local TypeGuard = require(script.Parent.Parent)
    local Base = TypeGuard.Vector3()

    describe("Init", function()
        it("should reject non-Vector3s", function()
            for _, Value in GetValues("Vector3") do
                expect(Base:Check(Value)).to.equal(false)
            end
        end)

        it("should accept Vector3s", function()
            expect(Base:Check(Vector3.new(1, 1))).to.equal(true)
        end)
    end)

    describe("Serialize, Deserialize", function()
        it("should correctly serialize & deserialize Vector3s", function()
            local Test = Vector3.new(1.465374757, 7452465.32542544543)
            expect(Base:Deserialize(Base:Serialize(Test))).to.equal(Test)
        end)
    end)
end