local function anyfn(...) return ({} :: any) end
it = it or anyfn
expect = expect or anyfn
describe = describe or anyfn

return function()
    local GetValues = require(script.Parent.Parent.Core._TestValues)
    local TypeGuard = require(script.Parent.Parent)
    local Base = TypeGuard.Font()

    describe("Init", function()
        it("should reject non-Fonts", function()
            for _, Value in GetValues("Font") do
                expect(Base:Check(Value)).to.equal(false)
            end
        end)

        it("should accept Fonts", function()
            expect(Base:Check(Font.new("Test"))).to.equal(true)
        end)
    end)

    describe("Serialize, Deserialize", function()
        it("should correctly serialize & deserialize Fonts", function()
            local Test = Font.new("Test", Enum.FontWeight.Thin, Enum.FontStyle.Italic)
            Test.Bold = true
            expect(Base:Deserialize(Base:Serialize(Test))).to.equal(Test)
        end)
    end)
end