local function anyfn(...) return ({} :: any) end
it = it or anyfn
expect = expect or anyfn
describe = describe or anyfn

return function()
    local GetValues = require(script.Parent._TestValues)
    local TypeGuard = require(script.Parent.Parent)
    local Base = TypeGuard.Optional(TypeGuard.Number())

    describe("Init", function()
        it("should accept either nil or the optional type, not other types", function()
            for _, Value in GetValues("Number", "Float") do
                expect(Base:Check(Value)).to.equal(false)
            end

            expect(Base:Check(123)).to.equal(true)
            expect(Base:Check(123.4)).to.equal(true)
        end)
    end)

    describe("Serialize, Deserialize", function()
        it("should serialize and deserialize the optional type or nil correctly", function()
            local Test = TypeGuard.Optional(TypeGuard.Number())
            expect(Test:Deserialize(Test:Serialize(123))).to.equal(123)
            expect(Test:Deserialize(Test:Serialize(nil))).to.equal(nil)
        end)
    end)
end