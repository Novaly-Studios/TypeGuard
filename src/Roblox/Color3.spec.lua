local function anyfn(...) return ({} :: any) end
it = it or anyfn
expect = expect or anyfn
describe = describe or anyfn

return function()
    local GetValues = require(script.Parent.Parent.Core._TestValues)
    local TypeGuard = require(script.Parent.Parent)
    local Base = TypeGuard.Color3()

    describe("Init", function()
        it("should reject non-Color3s", function()
            for _, Value in GetValues("Color3") do
                expect(Base:Check(Value)).to.equal(false)
            end
        end)

        it("should accept Color3s", function()
            expect(Base:Check(Color3.new(1, 1, 1))).to.equal(true)
        end)
    end)

    describe("Serialize, Deserialize", function()
        it("should correctly serialize & deserialize Color3s", function()
            local Test = Color3.new(0.132423, 0.124114, 0.6856743634563568)
            expect(Base:Deserialize(Base:Serialize(Test))).to.equal(Test)
        end)
    end)
end