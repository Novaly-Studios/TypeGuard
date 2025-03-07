local function anyfn(...) return ({} :: any) end
it = it or anyfn
expect = expect or anyfn
describe = describe or anyfn

return function()
    local GetValues = require(script.Parent.Parent.Core._TestValues)
    local TypeGuard = require(script.Parent.Parent)
    local Base = TypeGuard.Faces()

    describe("Init", function()
        it("should reject non-Faces", function()
            for _, Value in GetValues("Faces") do
                expect(Base:Check(Value)).to.equal(false)
            end
        end)

        it("should accept Faces", function()
            expect(Base:Check(Faces.new(Enum.NormalId.Top))).to.equal(true)
        end)
    end)

    describe("Serialize, Deserialize", function()
        it("should correctly serialize & deserialize Faces", function()
            local Test = Faces.new(Enum.NormalId.Top, Enum.NormalId.Left)
            expect(Base:Deserialize(Base:Serialize(Test))).to.equal(Test)
        end)
    end)
end