local function anyfn(...) return ({} :: any) end
it = it or anyfn
expect = expect or anyfn
describe = describe or anyfn

return function()
    local GetValues = require(script.Parent.Parent.Core._TestValues)
    local TypeGuard = require(script.Parent.Parent)
    local Base = TypeGuard.NumberSequenceKeypoint()

    describe("Init", function()
        it("should reject non-NumberSequenceKeypoints", function()
            for _, Value in GetValues("NumberSequenceKeypoint") do
                expect(Base:Check(Value)).to.equal(false)
            end
        end)

        it("should accept NumberSequenceKeypoints", function()
            expect(Base:Check(NumberSequenceKeypoint.new(1, 2, 3))).to.equal(true)
            expect(Base:Check(NumberSequenceKeypoint.new(1, 2))).to.equal(true)
        end)
    end)

    describe("Serialize, Deserialize", function()
        it("should correctly serialize & deserialize NumberSequenceKeypoints", function()
            local Test1 = NumberSequenceKeypoint.new(1, 2)
            local Test2 = NumberSequenceKeypoint.new(1, 2, 3)
            expect(Base:Deserialize(Base:Serialize(Test1))).to.equal(Test1)
            expect(Base:Deserialize(Base:Serialize(Test2))).to.equal(Test2)
        end)
    end)
end