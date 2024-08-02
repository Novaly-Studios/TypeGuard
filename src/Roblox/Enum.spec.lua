local function anyfn(...) return ({} :: any) end
it = it or anyfn
expect = expect or anyfn
describe = describe or anyfn

return function()
    local TypeGuard = require(script.Parent.Parent)

    describe("Init", function()
        it("should throw given non-EnumItem, non-Enum values", function()
            expect(function()
                TypeGuard.Enum(1)
            end).to.throw()

            expect(function()
                TypeGuard.Enum(true)
            end).to.throw()

            expect(function()
                TypeGuard.Enum({})
            end).to.throw()
        end)

        it("should not throw given EnumItem or Enum (or function) values", function()
            expect(function()
                TypeGuard.Enum(Enum.AccessoryType)
            end).never.to.throw()

            expect(function()
                TypeGuard.Enum(Enum.AccessoryType.Shirt)
            end).never.to.throw()

            expect(function()
                TypeGuard.Enum(function()
                    return Enum.AccessoryType.Shirt
                end)
            end).never.to.throw()
        end)
    end)

    describe("IsA", function()
        it("should accept an Enum item if the respective EnumItem is a sub-item", function()
            expect(TypeGuard.Enum(Enum.AccessoryType):Check(Enum.AccessoryType.Shirt)).to.equal(true)
            expect(TypeGuard.Enum(function()
                return Enum.AccessoryType
            end):Check(Enum.AccessoryType.Shirt)).to.equal(true)
        end)

        it("should reject EnumItems which are not part of the Enum class", function()
            expect(TypeGuard.Enum(Enum.AccessoryType):Check(Enum.AlphaMode.Overlay)).to.equal(false)
            expect(TypeGuard.Enum(function()
                return Enum.AccessoryType
            end):Check(Enum.AlphaMode.Overlay)).to.equal(false)
        end)

        it("should accept EnumItems which are equal", function()
            expect(TypeGuard.Enum(Enum.AccessoryType.Face):Check(Enum.AccessoryType.Face)).to.equal(true)
            expect(TypeGuard.Enum(function()
                return Enum.AccessoryType.Face
            end):Check(Enum.AccessoryType.Face)).to.equal(true)
        end)
    end)
end