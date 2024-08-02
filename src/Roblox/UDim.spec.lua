local function anyfn(...) return ({} :: any) end
it = it or anyfn
expect = expect or anyfn
describe = describe or anyfn

return function()
    local GetValues = require(script.Parent.Parent.Core._TestValues)
    local TypeGuard = require(script.Parent.Parent)
    local Base = TypeGuard.UDim()

    describe("Init", function()
        it("should reject non-UDims", function()
            for _, Value in GetValues("UDim1") do
                expect(Base:Check(Value)).to.equal(false)
            end
        end)

        it("should accept UDims", function()
            expect(Base:Check(UDim.new(1, 1))).to.equal(true)
        end)
    end)

    describe("Serialize, Deserialize", function()
        it("should correctly serialize & deserialize UDims", function()
            local Test = UDim.new(2.644233, 435)
            expect(Base:Deserialize(Base:Serialize(Test))).to.equal(Test)
        end)
    end)
end