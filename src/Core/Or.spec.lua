local function anyfn(...) return ({} :: any) end
it = it or anyfn
expect = expect or anyfn
describe = describe or anyfn

return function()
    local TypeGuard = require(script.Parent.Parent)

    describe("IsATypeIn", function()
        local TestTypes = TypeGuard.Or(TypeGuard.Boolean(), TypeGuard.String())

        it("should reject invalid types", function()
            expect(TestTypes:Check(1)).to.equal(false)
            expect(TestTypes:Check(function() end)).to.equal(false)
            expect(TestTypes:Check({})).to.equal(false)
        end)

        it("should accept valid types", function()
            expect(TestTypes:Check(true)).to.equal(true)
            expect(TestTypes:Check(false)).to.equal(true)
            expect(TestTypes:Check("Test")).to.equal(true)
        end)
    end)

    describe("IsAValueIn", function()
        local TestValues = TypeGuard.Or("X", "Y", 123, 456)

        it("should reject invalid values", function()
            expect(TestValues:Check(1)).to.equal(false)
            expect(TestValues:Check(function() end)).to.equal(false)
            expect(TestValues:Check({})).to.equal(false)
        end)

        it("should accept valid values", function()
            expect(TestValues:Check("X")).to.equal(true)
            expect(TestValues:Check("Y")).to.equal(true)
            expect(TestValues:Check(123)).to.equal(true)
            expect(TestValues:Check(456)).to.equal(true)
        end)
    end)

    describe("Serialize, Deserialize", function()
        it("should serialize and deserialize a single type correctly", function()
            local Test = TypeGuard.Or(TypeGuard.Number())
            local Buffer = Test:Serialize(123)
            expect(Test:Deserialize(Buffer)).to.equal(123)
        end)

        it("should serialize and deserialize a single value correctly", function()
            local Test = TypeGuard.Or("X", "Y")
            local Buffer = Test:Serialize("X")
            expect(Test:Deserialize(Buffer)).to.equal("X")
        end)

        it("should serialize and deserialize multiple types correctly", function()
            local Test = TypeGuard.Or(TypeGuard.Number(), TypeGuard.String())
            local Buffer = Test:Serialize(123)
            expect(Test:Deserialize(Buffer)).to.equal(123)
            Buffer = Test:Serialize("Test")
            expect(Test:Deserialize(Buffer)).to.equal("Test")
        end)

        it("should serialize and deserialize multiple values correctly", function()
            local Test = TypeGuard.Or("X", "Y", "Z")
            local Buffer = Test:Serialize("X")
            expect(Test:Deserialize(Buffer)).to.equal("X")
            Buffer = Test:Serialize("Y")
            expect(Test:Deserialize(Buffer)).to.equal("Y")
            Buffer = Test:Serialize("Z")
            expect(Test:Deserialize(Buffer)).to.equal("Z")
        end)
    end)
end