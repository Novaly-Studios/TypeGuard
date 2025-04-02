local function anyfn(...) return ({} :: any) end
it = it or anyfn
expect = expect or anyfn
describe = describe or anyfn

return function()
    local GetValues = require(script.Parent._TestValues)
    local TypeGuard = require(script.Parent.Parent)
    local Base = TypeGuard.Object()

    describe("Init", function()
        it("should reject non-table values", function()
            for _, Value in GetValues("Object", "Array") do
                expect(Base:Check(Value)).to.equal(false)
            end
        end)

        it("should accept object values", function()
            expect(Base:Check({})).to.equal(true)
            expect(Base:Check({Test = 123})).to.equal(true)
            expect(Base:Check({Test = false})).to.equal(true)
        end)
    end)

    describe("OfValueType", function()
        it("should accept an object with the given value type", function()
            expect(Base:OfValueType(TypeGuard.Number()):Check({Test = 123})).to.equal(true)
            expect(Base:OfValueType(TypeGuard.Number()):Check({Test = 123, Another = 987})).to.equal(true)
        end)

        it("should reject an object with a different value type", function()
            expect(Base:OfValueType(TypeGuard.Number()):Check({Test1 = 123, Test2 = "123"})).to.equal(false)
            expect(Base:OfValueType(TypeGuard.Number()):Check({Test = "123", Another = "987"})).to.equal(false)
        end)
    end)

    describe("OfKeyType", function()
        it("should accept an object with the given key type", function()
            expect(Base:OfKeyType(TypeGuard.String()):Check({Test = 123})).to.equal(true)
            expect(Base:OfKeyType(TypeGuard.String()):Check({Test = 123, Another = 987})).to.equal(true)
        end)

        it("should reject an object with a different key type", function()
            expect(Base:OfKeyType(TypeGuard.String()):Check({[{}] = true})).to.equal(false)
            expect(Base:OfKeyType(TypeGuard.String()):Check({[Instance.new("Part")] = true})).to.equal(false)
        end)
    end)

    describe("OfStructure", function()
        it("should accept an object with the given structure", function()
            expect(Base:OfStructure({
                Test = TypeGuard.Number(),
                Another = TypeGuard.Boolean()
            }):Check({Test = 123, Another = true})).to.equal(true)
        end)

        it("should reject an object with a different structure", function()
            expect(Base:OfStructure({
                Test = TypeGuard.Number(),
                Another = TypeGuard.Boolean()
            }):Check({Test = 123, Another = "true"})).to.equal(false)
        end)

        it("should accept additional fields when not in strict mode", function()
            expect(Base:OfStructure({
                Test = TypeGuard.Number(),
                Another = TypeGuard.Boolean()
            }):Check({Test = 123, Another = true, Test2 = "123"})).to.equal(true)
        end)

        it("should recurse given sub object TypeCheckers", function()
            expect(Base:OfStructure({
                Test = TypeGuard.Object({
                    Test = TypeGuard.Number(),
                    Another = TypeGuard.Boolean()
                })
            }):Check({Test = {Test = 123, Another = true}})).to.equal(true)
        end)
    end)

    describe("OfStructure + Strict", function()
        it("should accept an object with the given structure", function()
            expect(Base:OfStructure({
                Test = TypeGuard.Number(),
                Another = TypeGuard.Boolean()
            }):Strict():Check({Test = 123, Another = true})).to.equal(true)
        end)

        it("should reject an object with a different structure", function()
            expect(Base:OfStructure({
                Test = TypeGuard.Number(),
                Another = TypeGuard.Boolean()
            }):Strict():Check({Test = 123, Another = "true"})).to.equal(false)
        end)

        it("should reject additional fields when not in strict mode", function()
            expect(Base:OfStructure({
                Test = TypeGuard.Number(),
                Another = TypeGuard.Boolean()
            }):Strict():Check({Test = 123, Another = true, Test2 = "123"})).to.equal(false)
        end)

        it("should recurse given sub object TypeCheckers but not enforce strict recursively", function()
            expect(Base:OfStructure({
                Test = TypeGuard.Object({
                    Test = TypeGuard.Number(),
                    Another = TypeGuard.Boolean()
                })
            }):Strict():Check({Test = {Test = 123, Another = true, Final = {}}})).to.equal(true)
        end)
    end)

    describe("IsFrozen", function()
        it("should accept frozen objects", function()
            local Test = {X = 1, Y = 2, Z = 3}
            table.freeze(Test)
            expect(Base:IsFrozen():Check(Test)).to.equal(true)
        end)

        it("should reject non-frozen objects", function()
            local Test = {X = 1, Y = 2, Z = 3}
            expect(Base:IsFrozen():Check(Test)).to.equal(false)
        end)
    end)

    describe("CheckMetatable", function()
        it("should reject non-TypeCheckers", function()
            expect(function()
                Base:CheckMetatable(1)
            end).to.throw()

            expect(function()
                Base:CheckMetatable(function() end)
            end).to.throw()

            expect(function()
                Base:CheckMetatable({})
            end).to.throw()

            expect(function()
                Base:CheckMetatable(Instance.new("Part"))
            end).to.throw()
        end)

        it("should run the provided TypeChecker on the metatable", function()
            local Test = {}
            local MT = {__index = Test}
            setmetatable(Test, MT)
            expect(Base:CheckMetatable(Base:Equals(MT)):Check(Test)).to.equal(true)
        end)
    end)

    describe("OfClass", function()
        it("should reject non-tables", function()
            expect(function()
                Base:CheckMetatable(1)
            end).to.throw()

            expect(function()
                Base:CheckMetatable(function() end)
            end).to.throw()

            expect(function()
                Base:CheckMetatable(Instance.new("Part"))
            end).to.throw()
        end)

        it("should reject tables which are not intended to be an __index metatable", function()
            local Test = {}

            expect(function()
                Base:OfClass(Test)
            end).to.throw()
        end)

        it("should accept tables which are intended to be an __index metatable", function()
            local Test = {__index = {}}

            expect(function()
                Base:OfClass(Test)
            end).never.to.throw()
        end)

        it("should accept tables with the metatable equivalent to the provided class", function()
            local Test = {}
            Test.__index = Test

            local Object = setmetatable({}, Test)
            expect(Base:OfClass(Test):Check(Object)).to.equal(true)
        end)

        it("should reject tables with the metatable not equivalent to the provided class", function()
            local Test = {}
            Test.__index = Test

            local Test2 = {}
            Test2.__index = Test2

            local Object = setmetatable({}, Test)
            expect(Base:OfClass(Test2):Check(Object)).to.equal(false)
        end)

        it("should reject tables with no metatable", function()
            local Test = {}
            Test.__index = Test

            local Test2 = {}
            Test2.__index = Test2

            local Object = setmetatable({}, Test)
            expect(Base:OfClass(Test2):Check(Object)).to.equal(false)
        end)
    end)

    describe("And", function()
        it("should reject non-Indexable TypeChecker args", function()
            expect(function()
                TypeGuard.Number():And(1)
            end).to.throw()

            expect(function()
                TypeGuard.Number():And({})
            end).to.throw()

            expect(function()
                TypeGuard.Number():And(true)
            end).to.throw()

            expect(function()
                TypeGuard.Number():And(TypeGuard.Number())
            end).to.throw()

            expect(function()
                TypeGuard.Number():And(TypeGuard.String())
            end).to.throw()

            expect(function()
                TypeGuard.Number():And(TypeGuard.Array())
            end).to.throw()
        end)

        it("should accept Indexable TypeChecker args", function()
            expect(function()
                TypeGuard.Object({}):And(TypeGuard.Object({}))
            end).never.to.throw()
        end)

        it("should reject inputs if they do not satisfy an object conjunction", function()
            local Check = TypeGuard.Object({
                X = TypeGuard.Number();
            }):And(TypeGuard.Object({
                Y = TypeGuard.String();
            }))

            expect(Check:Check({
                X = 1;
            })).to.equal(false)

            expect(Check:Check({
                Y = "Test";
            })).to.equal(false)
        end)

        it("should accept inputs if they satisfy an object conjunction", function()
            local Check = TypeGuard.Object({
                X = TypeGuard.Number();
            }):And(TypeGuard.Object({
                Y = TypeGuard.String();
            }))

            expect(Check:Check({
                X = 1;
                Y = "Test";
            })).to.equal(true)
        end)
    end)

    describe("Serialize, Deserialize", function()
        it("should correctly serialize & deserialize an object with arbitrary string keys & values", function()
            local String = require(script.Parent.String)
            local Serializer = Base:OfKeyType(String()):OfValueType(String())
            local Test = {Key1 = "Test1", Key2 = "Test2"}
            local Result = Serializer:Deserialize(Serializer:Serialize(Test))

            for Key, Value in Test do
                expect(Result[Key]).to.equal(Value)
            end
        end)

        it("should correctly serialize & deserialize an object whose structure is strict", function()
            local String = require(script.Parent.String)
            local Test = {Key1 = "Test1", Key2 = "Test2"}
            local Structure = Base:OfStructure({
                Key1 = String();
                Key2 = String();
            }):Strict()

            local Result = Structure:Deserialize(Structure:Serialize(Test))
            for Key, Value in Test do
                expect(Result[Key]).to.equal(Value)
            end
        end)
    end)
end