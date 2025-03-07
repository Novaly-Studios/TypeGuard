local function anyfn(...) return ({} :: any) end
it = it or anyfn
expect = expect or anyfn
describe = describe or anyfn

return function()
    local GetValues = require(script.Parent.Parent.Core._TestValues)
    local TypeGuard = require(script.Parent.Parent)
    local Base = TypeGuard.Rect()

    describe("Init", function()
        it("should reject non-Rects", function()
            for _, Value in GetValues("Rect") do
                expect(Base:Check(Value)).to.equal(false)
            end
        end)

        it("should accept Rects", function()
            expect(Base:Check(Rect.new())).to.equal(true)
        end)
    end)

    describe("Serialize, Deserialize", function()
        it("should correctly serialize & deserialize Rects", function()
            local Test = Rect.new(Vector2.new(1.5, 0), Vector2.new(2.5, 20))
            expect(Base:Deserialize(Base:Serialize(Test))).to.equal(Test)
        end)
    end)
end