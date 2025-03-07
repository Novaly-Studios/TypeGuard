local function anyfn(...) return ({} :: any) end
it = it or anyfn
expect = expect or anyfn
describe = describe or anyfn

return function()
    local GetValues = require(script.Parent.Parent.Core._TestValues)
    local TypeGuard = require(script.Parent.Parent)
    local Base = TypeGuard.DateTime()

    describe("Init", function()
        it("should reject non-DateTimes", function()
            for _, Value in GetValues("DateTime") do
                expect(Base:Check(Value)).to.equal(false)
            end
        end)

        it("should accept DateTimes", function()
            expect(Base:Check(DateTime.fromUnixTimestamp(1741139693))).to.equal(true)
        end)
    end)

    describe("Serialize, Deserialize", function()
        it("should correctly serialize & deserialize DateTimes", function()
            local Test = DateTime.fromUnixTimestamp(1741139693)
            expect(Base:Deserialize(Base:Serialize(Test))).to.equal(Test)
        end)
    end)
end