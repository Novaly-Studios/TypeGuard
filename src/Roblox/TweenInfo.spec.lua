local function anyfn(...) return ({} :: any) end
it = it or anyfn
expect = expect or anyfn
describe = describe or anyfn

return function()
    local GetValues = require(script.Parent.Parent.Core._TestValues)
    local TypeGuard = require(script.Parent.Parent)
    local Base = TypeGuard.TweenInfo()

    describe("Init", function()
        it("should reject non-TweenInfos", function()
            for _, Value in GetValues("TweenInfo") do
                expect(Base:Check(Value)).to.equal(false)
            end
        end)

        it("should accept TweenInfos", function()
            expect(Base:Check(TweenInfo.new())).to.equal(true)
        end)
    end)

    describe("Serialize, Deserialize", function()
        it("should correctly serialize & deserialize TweenInfos", function()
            local Test1 = TweenInfo.new()
            local Test2 = TweenInfo.new(10)
            local Test3 = TweenInfo.new(10, Enum.EasingStyle.Elastic)
            local Test4 = TweenInfo.new(10, Enum.EasingStyle.Elastic, Enum.EasingDirection.Out)
            local Test5 = TweenInfo.new(10, Enum.EasingStyle.Elastic, Enum.EasingDirection.Out, 5)
            local Test6 = TweenInfo.new(10, Enum.EasingStyle.Elastic, Enum.EasingDirection.Out, 5, true)
            local Test7 = TweenInfo.new(10, Enum.EasingStyle.Elastic, Enum.EasingDirection.Out, 5, true, 2)
            expect(Base:Deserialize(Base:Serialize(Test1))).to.equal(Test1)
            expect(Base:Deserialize(Base:Serialize(Test2))).to.equal(Test2)
            expect(Base:Deserialize(Base:Serialize(Test3))).to.equal(Test3)
            expect(Base:Deserialize(Base:Serialize(Test4))).to.equal(Test4)
            expect(Base:Deserialize(Base:Serialize(Test5))).to.equal(Test5)
            expect(Base:Deserialize(Base:Serialize(Test6))).to.equal(Test6)
            expect(Base:Deserialize(Base:Serialize(Test7))).to.equal(Test7)
        end)
    end)
end