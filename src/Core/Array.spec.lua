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

        --[[ it("should serialize and deserialize all combinations", function()
            for ID, Value in GetValues("INCLUDE", "Array") do
                local Serialized = Base:Serialize(Value)
                local Deserialized = Base:Deserialize(Serialized)
                expect(Deserialized).to.equal(Value)
            end
        end) ]]
    end)

    describe("OfLength", function()
        it("should reject arrays shorter than the specified length", function()
            expect(Base:OfLength(5):Check({1, 2, 3, 4})).to.equal(false)
            expect(Base:OfLength(function()
                return 5
            end):Check({1, 2, 3, 4})).to.equal(false)
        end)

        it("should accept arrays longer than the specified length", function()
            expect(Base:OfLength(5):Check({1, 2, 3, 4, 5})).to.equal(true)
            expect(Base:OfLength(function()
                return 5
            end):Check({1, 2, 3, 4, 5})).to.equal(true)
        end)

        it("should reject arrays greater than the specified length", function()
            expect(Base:OfLength(5):Check({1, 2, 3, 4, 5, 6})).to.equal(false)
            expect(Base:OfLength(function()
                return 5
            end):Check({1, 2, 3, 4, 5, 6})).to.equal(false)
        end)

        it("should serialize and deserialize", function()
            local Serializer = Base:OfType(TypeGuard.Number()):OfLength(3)
            local Serialized = Serializer:Serialize({1, 2, 3})
            local Deserialized = Serializer:Deserialize(Serialized)
            expect(#Deserialized).to.equal(3)
            expect(Deserialized[1]).to.equal(1)
            expect(Deserialized[2]).to.equal(2)
            expect(Deserialized[3]).to.equal(3)
        end)
    end)

    describe("MinLength", function()
        it("should reject arrays shorter than the specified length", function()
            expect(Base:MinLength(5):Check({1, 2, 3, 4})).to.equal(false)
            expect(Base:MinLength(function()
                return 5
            end):Check({1, 2, 3, 4})).to.equal(false)
        end)

        it("should accept arrays equal to the specified length", function()
            expect(Base:MinLength(5):Check({1, 2, 3, 4, 5})).to.equal(true)
            expect(Base:MinLength(function()
                return 5
            end):Check({1, 2, 3, 4, 5})).to.equal(true)
        end)

        it("should accept arrays longer than the specified length", function()
            expect(Base:MinLength(5):Check({1, 2, 3, 4, 5, 6})).to.equal(true)
            expect(Base:MinLength(function()
                return 5
            end):Check({1, 2, 3, 4, 5, 6})).to.equal(true)
        end)

        it("should serialize and deserialize", function()
            local Serializer = Base:OfType(TypeGuard.Number()):MinLength(2)
            local Serialized = Serializer:Serialize({1, 2, 3})
            local Deserialized = Serializer:Deserialize(Serialized)
            expect(#Deserialized).to.equal(3)
            expect(Deserialized[1]).to.equal(1)
            expect(Deserialized[2]).to.equal(2)
            expect(Deserialized[3]).to.equal(3)
        end)
    end)

    describe("MaxLength", function()
        it("should reject arrays longer than the specified length", function()
            expect(Base:MaxLength(5):Check({1, 2, 3, 4, 5, 6})).to.equal(false)
            expect(Base:MaxLength(function()
                return 5
            end):Check({1, 2, 3, 4, 5, 6})).to.equal(false)
        end)

        it("should accept arrays equal to the specified length", function()
            expect(Base:MaxLength(5):Check({1, 2, 3, 4, 5})).to.equal(true)
            expect(Base:MaxLength(function()
                return 5
            end):Check({1, 2, 3, 4, 5})).to.equal(true)
        end)

        it("should accept arrays shorter than the specified length", function()
            expect(Base:MaxLength(5):Check({1, 2, 3, 4})).to.equal(true)
            expect(Base:MaxLength(function()
                return 5
            end):Check({1, 2, 3, 4})).to.equal(true)
        end)

        it("should serialize and deserialize", function()
            local Serializer = Base:OfType(TypeGuard.Number()):MaxLength(4)
            local Serialized = Serializer:Serialize({1, 2, 3})
            local Deserialized = Serializer:Deserialize(Serialized)
            expect(#Deserialized).to.equal(3)
            expect(Deserialized[1]).to.equal(1)
            expect(Deserialized[2]).to.equal(2)
            expect(Deserialized[3]).to.equal(3)
        end)
    end)

    describe("Contains", function()
        it("should accept arrays containing the specified element", function()
            expect(Base:Contains(1):Check({1, 2, 3, 4})).to.equal(true)
            expect(Base:Contains(function()
                return 1
            end):Check({1, 2, 3, 4})).to.equal(true)
        end)

        it("should reject arrays not containing the specified element", function()
            expect(Base:Contains(1):Check({2, 3, 4})).to.equal(false)
            expect(Base:Contains(function()
                return 1
            end):Check({2, 3, 4})).to.equal(false)
        end)

        it("should serialize and deserialize", function()
            local Serializer = Base:OfType(TypeGuard.Number()):Contains(3)
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
            expect(Base:OfType(TypeGuard.Number()):Check({1, 2, 3, 4})).to.equal(true)
        end)

        it("should reject arrays containing elements of other types", function()
            expect(Base:OfType(TypeGuard.Number()):Check({1, "Test", 3, 4})).to.equal(false)
        end)

        it("should serialize and deserialize", function()
            local Serializer = Base:OfType(TypeGuard.Number())
            local Serialized = Serializer:Serialize({1, 2, 3})
            local Deserialized = Serializer:Deserialize(Serialized)
            expect(#Deserialized).to.equal(3)
            expect(Deserialized[1]).to.equal(1)
            expect(Deserialized[2]).to.equal(2)
            expect(Deserialized[3]).to.equal(3)
        end)
    end)

    describe("ContainsValueOfType", function()
        it("should reject non-TypeCheckers as first arg", function()
            expect(function()
                Base:ContainsValueOfType(1)
            end).to.throw()

            expect(function()
                Base:ContainsValueOfType(nil)
            end).to.throw()

            expect(function()
                Base:ContainsValueOfType("Test")
            end).to.throw()
        end)

        it("should accept TypeCheckers as first arg", function()
            expect(function()
                Base:ContainsValueOfType(TypeGuard.Number())
            end).never.to.throw()
        end)

        it("should reject non-numbers as second arg", function()
            expect(function()
                Base:ContainsValueOfType(TypeGuard.Number(), {})
            end).to.throw()

            expect(function()
                Base:ContainsValueOfType(TypeGuard.Number(), "Test")
            end).to.throw()
        end)

        it("should accept numbers or functions as second arg", function()
            expect(function()
                Base:ContainsValueOfType(TypeGuard.Number(), 1)
            end).never.to.throw()

            expect(function()
                Base:ContainsValueOfType(TypeGuard.Number(), function() return 1 end)
            end).never.to.throw()
        end)

        it("should accept arrays containing an element satisfied by the specified TypeChecker & reject when not present", function()
            expect(Base:ContainsValueOfType(TypeGuard.Number()):Check({1, 2, 3, 4})).to.equal(true)
            expect(Base:ContainsValueOfType(TypeGuard.String()):Check({"Str", 2, 3, 4})).to.equal(true)
            expect(Base:ContainsValueOfType(
                TypeGuard.Object({Value = TypeGuard.Boolean()})
            ):Check({
                1, 2, 3,
                {Value = false}
            })).to.equal(true)

            expect(Base:ContainsValueOfType(TypeGuard.Number()):Check({"X", "Y"})).to.equal(false)
            expect(Base:ContainsValueOfType(TypeGuard.String()):Check({1, 2, 3, 4})).to.equal(false)
            expect(Base:ContainsValueOfType(TypeGuard.Object({Value = TypeGuard.Boolean()})):Check({1, 2, 3})).to.equal(false)
        end)

        it("should correctly search given a starting index", function()
            expect(Base:ContainsValueOfType(TypeGuard.Number(), 1):Check({1, 2, "P", "Q"})).to.equal(true)
            expect(Base:ContainsValueOfType(TypeGuard.Number(), 2):Check({1, 2, "P", "Q"})).to.equal(true)
            expect(Base:ContainsValueOfType(TypeGuard.Number(), 3):Check({1, 2, "P", "Q"})).to.equal(false)
        end)

        it("should accept functional constraint value for starting index", function()
            expect(Base:ContainsValueOfType(TypeGuard.Number(), function()
                return 1
            end):Check({1, 2, "P", "Q"})).to.equal(true)

            expect(Base:ContainsValueOfType(TypeGuard.Number(), function()
                return 3
            end):Check({1, 2, "P", "Q"})).to.equal(false)
        end)

        it("should serialize and deserialize", function()
            local Serializer = Base:OfType(TypeGuard.Number()):ContainsValueOfType(TypeGuard.Number())
            local Serialized = Serializer:Serialize({1, 2, 3})
            local Deserialized = Serializer:Deserialize(Serialized)
            expect(#Deserialized).to.equal(3)
            expect(Deserialized[1]).to.equal(1)
            expect(Deserialized[2]).to.equal(2)
            expect(Deserialized[3]).to.equal(3)
        end)
    end)

    describe("OfStructure", function()
        it("should throw for non TypeCheckers inside the template array", function()
            expect(function()
                Base:OfStructure({1})
            end).to.throw()

            expect(function()
                Base:OfStructure({function() end})
            end).to.throw()

            expect(function()
                Base:OfStructure({{}})
            end).to.throw()
        end)

        it("should not throw for TypeCheckers inside the template array", function()
            expect(function()
                Base:OfStructure({TypeGuard.Number()})
            end).never.to.throw()

            expect(function()
                Base:OfStructure({TypeGuard.String()})
            end).never.to.throw()

            expect(function()
                Base:OfStructure({TypeGuard.Array()})
            end).never.to.throw()
        end)

        it("should accept arrays with additional contents", function()
            expect(Base:OfStructure({TypeGuard.Number(), TypeGuard.Number()}):Check({1, 2, 3})).to.equal(true)
        end)

        it("should accept an array of a correct type (numerical)", function()
            expect(Base:OfStructure({
                TypeGuard.Number(), TypeGuard.Number(),
                TypeGuard.Number(), TypeGuard.Number()
            }):Check({1, 2, 3, 4})).to.equal(true)
        end)

        it("should reject an array of a incorrect type (numerical)", function()
            expect(Base:OfStructure({
                TypeGuard.Number(), TypeGuard.Number(),
                TypeGuard.Number(), TypeGuard.Number()
            }):Check({1, 2, "Test", 4})).to.equal(false)
        end)

        it("should check recursively", function()
            expect(Base:OfStructure({
                [1] = Base:OfStructure({TypeGuard.String()});
                [2] = Base:OfStructure({TypeGuard.Boolean()});
            }):Check({ {"Test"}, {true} })).to.equal(true)
        end)

        it("should serialize and deserialize", function()
            local Serializer = Base:OfType(TypeGuard.Number()):OfStructure({TypeGuard.Number(), TypeGuard.Number(), TypeGuard.Number()})
            local Serialized = Serializer:Serialize({1, 2, 3})
            local Deserialized = Serializer:Deserialize(Serialized)
            expect(#Deserialized).to.equal(3)
            expect(Deserialized[1]).to.equal(1)
            expect(Deserialized[2]).to.equal(2)
            expect(Deserialized[3]).to.equal(3)
        end)
    end)

    describe("Strict", function()
        it("should reject arrays with additional contents", function()
            local Checker = Base:OfStructure({TypeGuard.Number(), TypeGuard.Number()}):Strict()
            expect(Checker:Check({1, 2})).to.equal(true)
            expect(Checker:Check({1, 2, 3})).to.equal(false)
        end)

        it("should serialize and deserialize", function()
            local Serializer = Base:OfStructure({TypeGuard.Number(), TypeGuard.Number(), TypeGuard.Number()}):Strict()
            local Serialized = Serializer:Serialize({1, 2, 3})
            local Deserialized = Serializer:Deserialize(Serialized)
            expect(#Deserialized).to.equal(3)
            expect(Deserialized[1]).to.equal(1)
            expect(Deserialized[2]).to.equal(2)
            expect(Deserialized[3]).to.equal(3)
        end)
    end)

    describe("IsFrozen", function()
        it("should accept frozen arrays", function()
            local Test = {1, 2, 3}
            table.freeze(Test)
            expect(Base:IsFrozen():Check(Test)).to.equal(true)
        end)

        it("should reject non-frozen arrays", function()
            local Test = {1, 2, 3}
            expect(Base:IsFrozen():Check(Test)).to.equal(false)
        end)

        it("should serialize and deserialize", function()
            local Serializer = Base:OfType(TypeGuard.Number()):IsFrozen()
            local Serialized = Serializer:Serialize(table.freeze({1, 2, 3}))
            local Deserialized = Serializer:Deserialize(Serialized)
            expect(#Deserialized).to.equal(3)
            expect(Deserialized[1]).to.equal(1)
            expect(Deserialized[2]).to.equal(2)
            expect(Deserialized[3]).to.equal(3)
            expect(table.isfrozen(Deserialized)).to.equal(true)
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
            expect(Base:IsOrdered(true):Check({3, 2, 1})).to.equal(true)
            expect(Base:IsOrdered(true):Check({1, 2, 3})).to.equal(false)
            expect(Base:IsOrdered(function()
                return true
            end):Check({3, 2, 1})).to.equal(true)
            expect(Base:IsOrdered(function()
                return true
            end):Check({1, 2, 3})).to.equal(false)
        end)

        it("should check if an array is ordered as ascending", function()
            expect(Base:IsOrdered(false):Check({1, 2, 3})).to.equal(true)
            expect(Base:IsOrdered(false):Check({3, 2, 1})).to.equal(false)
            expect(Base:IsOrdered():Check({1, 2, 3})).to.equal(true)
            expect(Base:IsOrdered():Check({3, 2, 1})).to.equal(false)
            expect(Base:IsOrdered(function()
                return false
            end):Check({1, 2, 3})).to.equal(true)
            expect(Base:IsOrdered(function()
                return false
            end):Check({3, 2, 1})).to.equal(false)
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
            local Serializer = Base:OfType(TypeGuard.Number()):IsOrdered()
            local Serialized = Serializer:Serialize({1, 2, 3})
            local Deserialized = Serializer:Deserialize(Serialized)
            expect(#Deserialized).to.equal(3)
            expect(Deserialized[1]).to.equal(1)
            expect(Deserialized[2]).to.equal(2)
            expect(Deserialized[3]).to.equal(3)
        end)
    end)
end