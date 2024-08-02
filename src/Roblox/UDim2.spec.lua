local function anyfn(...) return ({} :: any) end
it = it or anyfn
expect = expect or anyfn
describe = describe or anyfn

return function()
    local GetValues = require(script.Parent.Parent.Core._TestValues)
    local TypeGuard = require(script.Parent.Parent)
    local Base = TypeGuard.UDim2()

    describe("Init", function()
        it("should reject non-UDim2s", function()
            for _, Value in GetValues("UDim2") do
                expect(Base:Check(Value)).to.equal(false)
            end
        end)

        it("should accept UDim2s", function()
            expect(Base:Check(UDim2.new(1, 1))).to.equal(true)
        end)
    end)

    describe("Serialize, Deserialize", function()
        it("should correctly serialize & deserialize UDim2s", function()
            local Test = UDim2.new(2.644233, 435, 3.542544, 123)
            expect(Base:Deserialize(Base:Serialize(Test))).to.equal(Test)
        end)
    end)
end