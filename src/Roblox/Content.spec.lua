local function anyfn(...) return ({} :: any) end
it = it or anyfn
expect = expect or anyfn
describe = describe or anyfn

return function()
    local GetValues = require(script.Parent.Parent.Core._TestValues)
    local TypeGuard = require(script.Parent.Parent)
    local Base = TypeGuard.Content()

    describe("Init", function()
        it("should reject non-Contents", function()
            for _, Value in GetValues("Content") do
                expect(Base:Check(Value)).to.equal(false)
            end
        end)

        it("should accept Contents", function()
            expect(Base:Check(Content.fromUri(""))).to.equal(true)
        end)
    end)

    describe("Serialize, Deserialize", function()
        it("should correctly serialize & deserialize Contents", function()
            local Test = Content.fromUri("rbxassetid://12345")
            expect(Base:Deserialize(Base:Serialize(Test))).to.equal(Test)
        end)
    end)
end