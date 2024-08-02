local function anyfn(...) return ({} :: any) end
it = it or anyfn
expect = expect or anyfn
describe = describe or anyfn

return function()
    local GetValues = require(script.Parent.Parent.Core._TestValues)
    local TypeGuard = require(script.Parent.Parent)
    local Base = TypeGuard.NumberSequence()

    describe("Init", function()
        it("should reject non-NumberSequences", function()
            for _, Value in GetValues("NumberSequence") do
                expect(Base:Check(Value)).to.equal(false)
            end
        end)

        it("should accept NumberSequences", function()
            expect(Base:Check(NumberSequence.new({NumberSequenceKeypoint.new(0, 2), NumberSequenceKeypoint.new(1, 5, 3)}))).to.equal(true)
            expect(Base:Check(NumberSequence.new(1, 2))).to.equal(true)
        end)
    end)

    describe("Serialize, Deserialize", function()
        it("should correctly serialize & deserialize NumberSequences", function()
            local Test1 = NumberSequence.new(1, 2)
            local Test2 = NumberSequence.new({NumberSequenceKeypoint.new(0, 2), NumberSequenceKeypoint.new(1, 5, 3)})
            print(">>>>>>>>>", pcall(function()
                Base:Deserialize(Base:Serialize(Test1))
            end))
            expect(Base:Deserialize(Base:Serialize(Test1))).to.equal(Test1)
            expect(Base:Deserialize(Base:Serialize(Test2))).to.equal(Test2)
        end)
    end)
end