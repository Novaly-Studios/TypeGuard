local function anyfn(...) return ({} :: any) end
it = it or anyfn
expect = expect or anyfn
describe = describe or anyfn

return function()
    local GetValues = require(script.Parent._TestValues)
    local TypeGuard = require(script.Parent.Parent)
    local Base = TypeGuard.Array()

    describe("Init", function()
        it("should reject non-arrays", function()
            for _, Value in GetValues("Array") do
                local Test = Base:Check(Value)
                expect(Test).to.equal(false)
            end
        end)

        it("should accept arrays", function()
            expect(Base:Check({})).to.equal(true)
            expect(Base:Check({1})).to.equal(true)
            expect(Base:Check({1, 2})).to.equal(true)
        end)

        it("should serialize and deserialize", function()
            local Serializer = Base
            local Serialized = Serializer:Serialize({1, 2, 3, "XYZ"})
            local Deserialized = Serializer:Deserialize(Serialized)
            expect(#Deserialized).to.equal(4)
            expect(Deserialized[1]).to.equal(1)
            expect(Deserialized[2]).to.equal(2)
            expect(Deserialized[3]).to.equal(3)
            expect(Deserialized[4]).to.equal("XYZ")
        end)

        it("should serialize and deserialize arrays with gaps", function()
            local Test = TypeGuard.Array(TypeGuard.Optional(TypeGuard.Number()))
            local Serialized = Test:Serialize({1, nil, 3, nil, 5})
            local Deserialized = Test:Deserialize(Serialized)
            expect(#Deserialized).to.equal(5)
            expect(Deserialized[1]).to.equal(1)
            expect(Deserialized[2]).to.equal(nil)
            expect(Deserialized[3]).to.equal(3)
            expect(Deserialized[4]).to.equal(nil)
            expect(Deserialized[5]).to.equal(5)
        end)
    end)

    describe("OfLength", function()
        it("should reject arrays shorter than the specified length", function()
            expect(Base:OfLength(5):Check({1, 2, 3, 4})).to.equal(false)
        end)

        it("should accept arrays longer than the specified length", function()
            expect(Base:OfLength(5):Check({1, 2, 3, 4, 5})).to.equal(true)
        end)

        it("should reject arrays greater than the specified length", function()
            expect(Base:OfLength(5):Check({1, 2, 3, 4, 5, 6})).to.equal(false)
        end)

        it("should serialize and deserialize", function()
            local Serializer = TypeGuard.Array(TypeGuard.Number()):OfLength(3)
            local Serialized = Serializer:Serialize({1, 2, 3})
            local Deserialized = Serializer:Deserialize(Serialized)
            expect(#Deserialized).to.equal(3)
            expect(Deserialized[1]).to.equal(1)
            expect(Deserialized[2]).to.equal(2)
            expect(Deserialized[3]).to.equal(3)
        end)
    end)

    describe("MinSize", function()
        it("should reject arrays shorter than the specified length", function()
            expect(Base:MinSize(5):Check({1, 2, 3, 4})).to.equal(false)
            expect(Base:MinSize(function()
                return 5
            end):Check({1, 2, 3, 4})).to.equal(false)
        end)

        it("should accept arrays equal to the specified length", function()
            expect(Base:MinSize(5):Check({1, 2, 3, 4, 5})).to.equal(true)
            expect(Base:MinSize(function()
                return 5
            end):Check({1, 2, 3, 4, 5})).to.equal(true)
        end)

        it("should accept arrays longer than the specified length", function()
            expect(Base:MinSize(5):Check({1, 2, 3, 4, 5, 6})).to.equal(true)
            expect(Base:MinSize(function()
                return 5
            end):Check({1, 2, 3, 4, 5, 6})).to.equal(true)
        end)

        it("should serialize and deserialize", function()
            local Serializer = TypeGuard.Array(TypeGuard.Number()):MinSize(2)
            local Serialized = Serializer:Serialize({1, 2, 3})
            local Deserialized = Serializer:Deserialize(Serialized)
            expect(#Deserialized).to.equal(3)
            expect(Deserialized[1]).to.equal(1)
            expect(Deserialized[2]).to.equal(2)
            expect(Deserialized[3]).to.equal(3)
        end)
    end)

    describe("MaxSize", function()
        it("should reject arrays longer than the specified length", function()
            expect(Base:MaxSize(5):Check({1, 2, 3, 4, 5, 6})).to.equal(false)
            expect(Base:MaxSize(function()
                return 5
            end):Check({1, 2, 3, 4, 5, 6})).to.equal(false)
        end)

        it("should accept arrays equal to the specified length", function()
            expect(Base:MaxSize(5):Check({1, 2, 3, 4, 5})).to.equal(true)
            expect(Base:MaxSize(function()
                return 5
            end):Check({1, 2, 3, 4, 5})).to.equal(true)
        end)

        it("should accept arrays shorter than the specified length", function()
            expect(Base:MaxSize(5):Check({1, 2, 3, 4})).to.equal(true)
            expect(Base:MaxSize(function()
                return 5
            end):Check({1, 2, 3, 4})).to.equal(true)
        end)

        it("should serialize and deserialize", function()
            local Serializer = TypeGuard.Array(TypeGuard.Number()):MaxSize(4)
            local Serialized = Serializer:Serialize({1, 2, 3})
            local Deserialized = Serializer:Deserialize(Serialized)
            expect(#Deserialized).to.equal(3)
            expect(Deserialized[1]).to.equal(1)
            expect(Deserialized[2]).to.equal(2)
            expect(Deserialized[3]).to.equal(3)
        end)
    end)

    describe("OfType", function()
        it("should accept arrays containing only the specified type", function()
            expect(TypeGuard.Array(TypeGuard.Number()):Check({1, 2, 3, 4})).to.equal(true)
        end)

        it("should reject arrays containing elements of other types", function()
            expect(TypeGuard.Array(TypeGuard.Number()):Check({1, "Test", 3, 4})).to.equal(false)
        end)

        it("should serialize and deserialize", function()
            local Serializer = TypeGuard.Array(TypeGuard.Number())
            local Serialized = Serializer:Serialize({1, 2, 3})
            local Deserialized = Serializer:Deserialize(Serialized)
            expect(#Deserialized).to.equal(3)
            expect(Deserialized[1]).to.equal(1)
            expect(Deserialized[2]).to.equal(2)
            expect(Deserialized[3]).to.equal(3)
        end)
    end)

    describe("IsOrdered", function()
        it("should allow nil params", function()
            expect(function()
                Base:IsOrdered()
            end).never.to.throw()
        end)

        it("should accept params which are booleans only if not nil (for ascending & descending)", function()
            expect(function()
                Base:IsOrdered(true)
                Base:IsOrdered(false)
            end).never.to.throw()

            expect(function()
                Base:IsOrdered(1)
            end).to.throw()

            expect(function()
                Base:IsOrdered({})
            end).to.throw()
        end)

        it("should accept single-item arrays", function()
            expect(Base:IsOrdered():Check({1})).to.equal(true)
        end)

        it("should check if an array is ordered as descending", function()
            expect(Base:IsOrdered(false):Check({3, 2, 1})).to.equal(true)
            expect(Base:IsOrdered(false):Check({1, 2, 3})).to.equal(false)
        end)

        it("should check if an array is ordered as ascending", function()
            expect(Base:IsOrdered(true):Check({1, 2, 3})).to.equal(true)
            expect(Base:IsOrdered(true):Check({3, 2, 1})).to.equal(false)
        end)

        it("should check if an array is ordered either way (if no arg)", function()
            expect(Base:IsOrdered():Check({1, 2, 3})).to.equal(true)
            expect(Base:IsOrdered():Check({3, 2, 1})).to.equal(true)
        end)

        it("should reject non ordered arrays", function()
            expect(Base:IsOrdered(false):Check({1, 2, 4, 3})).to.equal(false)
            expect(Base:IsOrdered(true):Check({1, 2, 4, 3})).to.equal(false)
            expect(Base:IsOrdered(function()
                return false
            end):Check({1, 2, 4, 3})).to.equal(false)
            expect(Base:IsOrdered(function()
                return true
            end):Check({1, 2, 4, 3})).to.equal(false)
        end)

        it("should serialize and deserialize", function()
            local Serializer = TypeGuard.Array(TypeGuard.Number()):IsOrdered()
            local Serialized = Serializer:Serialize({1, 2, 3})
            local Deserialized = Serializer:Deserialize(Serialized)
            expect(#Deserialized).to.equal(3)
            expect(Deserialized[1]).to.equal(1)
            expect(Deserialized[2]).to.equal(2)
            expect(Deserialized[3]).to.equal(3)
        end)
    end)
end