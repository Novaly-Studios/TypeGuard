local function anyfn(...) return ({} :: any) end
it = it or anyfn
expect = expect or anyfn
describe = describe or anyfn

return function()
    local GetValues = require(script.Parent._TestValues)
    local TypeGuard = require(script.Parent.Parent)
    local Base = TypeGuard.Object()

    describe("Init", function()
        it("should reject non-object values", function()            
            for _, Value in GetValues("Object") do
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
            expect(Base:CheckMetatable(TypeGuard.Number()):Check(Test)).to.equal(false)
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
        it("should reject non-TypeChecker args", function()
            expect(function()
                TypeGuard.Number():And(1)
            end).to.throw()

            expect(function()
                TypeGuard.Number():And({})
            end).to.throw()

            expect(function()
                TypeGuard.Number():And(true)
            end).to.throw()
        end)

        it("should accept TypeChecker args", function()
            expect(function()
                TypeGuard.Number():And(TypeGuard.Number())
            end).never.to.throw()

            expect(function()
                TypeGuard.Number():And(TypeGuard.String())
            end).never.to.throw()

            expect(function()
                TypeGuard.Number():And(TypeGuard.Array())
            end).never.to.throw()
        end)

        it("should reject inputs if they do not satisfy at least one TypeChecker in the and chain", function()
            local Check = TypeGuard.Number():And(TypeGuard.Boolean())
            expect(Check:Check(1)).to.equal(false)
            expect(Check:Check(true)).to.equal(false)
            expect(Check:Check(false)).to.equal(false)
        end)

        it("should accept inputs if they satisfy all TypeCheckers in the and chain and reject if they do not (for objects)", function()
            local Check = TypeGuard.Object():OfStructure({X = TypeGuard.Number()})
                            :And(TypeGuard.Object():OfStructure({Y = TypeGuard.String()}))
                            :And(TypeGuard.Object():OfStructure({Z = TypeGuard.Boolean()}))

            expect(Check:Check({X = 1, Y = "A", Z = false})).to.equal(true)
            expect(Check:Check({X = 1})).to.equal(false)
            expect(Check:Check({X = 1, Y = "A", Z = {}})).to.equal(false)
        end)

        it("should accept inputs if they satisfy all TypeCheckers in the and chain and reject if they do not (for Instances)", function()
            local Check = TypeGuard.Instance():OfStructure({Name = TypeGuard.String()})
                          :And(TypeGuard.Instance():OfStructure({
                              SomeChild = TypeGuard.Instance();
                          }))

            local TestInstance = Instance.new("Folder")
                local SomeChild = Instance.new("Folder")
                SomeChild.Name = "SomeChild"
                SomeChild.Parent = TestInstance

            local TestInstance2 = Instance.new("Folder")
                local SomeChild2 = Instance.new("Folder")
                SomeChild2.Name = "SomeChild2"
                SomeChild2.Parent = TestInstance2

            expect(Check:Check(TestInstance)).to.equal(true)
            expect(Check:Check(TestInstance2)).to.equal(false)
        end)
    end)

    describe("FromTemplate", function()
        it("should generate from primitive types", function()
            local Test = TypeGuard.FromTemplate("string")
            expect(Test:Check("Test")).to.equal(true)
            expect(Test:Check(123)).to.equal(false)

            Test = TypeGuard.FromTemplate(1)
            expect(Test:Check(123)).to.equal(true)
            expect(Test:Check("Test")).to.equal(false)

            Test = TypeGuard.FromTemplate(false)
            expect(Test:Check(true)).to.equal(true)
            expect(Test:Check("Test")).to.equal(false)

            Test = TypeGuard.FromTemplate(function() end)
            expect(Test:Check(function() end)).to.equal(true)
            expect(Test:Check("Test")).to.equal(false)

            Test = TypeGuard.FromTemplate(nil)
            expect(Test:Check(nil)).to.equal(true)
            expect(Test:Check("Test")).to.equal(false)

            Test = TypeGuard.FromTemplate(newproxy(true))
            expect(Test:Check(newproxy(true))).to.equal(true)
            expect(Test:Check("Test")).to.equal(false)

            Test = TypeGuard.FromTemplate(coroutine.create(function() end))
            expect(Test:Check(coroutine.create(function() end))).to.equal(true)
        end)

        it("should generate from Luau types", function()
            local Test = TypeGuard.FromTemplate(Enum.KeyCode.A)
            expect(Test:Check(Enum.KeyCode.A)).to.equal(true)
            expect(Test:Check("Test")).to.equal(false)

            Test = TypeGuard.FromTemplate(Color3.new(1, 1, 1))
            expect(Test:Check(Color3.new(0, 0, 0))).to.equal(true)
            expect(Test:Check("Test")).to.equal(false)
        end)

        it("should generate from Instances: flat", function()
            local Tree = Instance.new("Model")
                local Part1 = Instance.new("Part")
                Part1.Name = "Part1"
                Part1.Parent = Tree
                local Part2 = Instance.new("Part")
                Part2.Name = "Part2"
                Part2.Parent = Tree

            local Test = TypeGuard.FromTemplate(Tree)
            expect(Test:Check(Instance.new("Model"))).to.equal(false)
            expect(Test:Check(Tree)).to.equal(true)
            expect(Test:Check("Test")).to.equal(false)
        end)

        it("should generate from Instances: deep", function()
            local Tree = Instance.new("Model")
                local Part1 = Instance.new("Part")
                Part1.Name = "Part1"
                Part1.Parent = Tree
                local Part2 = Instance.new("Part")
                Part2.Name = "Part2"
                Part2.Parent = Tree
                    local Part2Part1 = Instance.new("Part")
                    Part2Part1.Name = "Part2Part1"
                    Part2Part1.Parent = Part2

            local Test = TypeGuard.FromTemplate(Tree)
            expect(Test:Check(Instance.new("Model"))).to.equal(false)
            expect(Test:Check(Tree)).to.equal(true)
            expect(Test:Check("Test")).to.equal(false)
        end)

        it("should generate from arrays: single types", function()
            local Test = TypeGuard.FromTemplate({"Str1", "Str2", "Str3"})
            expect(Test:Check({"Test"})).to.equal(true)
        end)

        it("should generate from arrays: multiple types", function()
            local Test = TypeGuard.FromTemplate({"Str1", 1, false})
            expect(Test:Check({"Test"})).to.equal(true)
            expect(Test:Check({1})).to.equal(true)
            expect(Test:Check({false})).to.equal(true)
            expect(Test:Check({true})).to.equal(true)
        end)

        it("should generate from objects: flat", function()
            local Test = TypeGuard.FromTemplate({})
            expect(Test:Check({})).to.equal(true)
            expect(Test:Check("Test")).to.equal(false)

            Test = TypeGuard.FromTemplate({Test = 1})
            expect(Test:Check({Test = 1})).to.equal(true)
            expect(Test:Check({Test = "1"})).to.equal(false)
        end)

        it("should generate strict objects: flat", function()
            local Test = TypeGuard.FromTemplate({}, true)
            expect(Test:Check({})).to.equal(true)
            expect(Test:Check("Test")).to.equal(false)

            Test = TypeGuard.FromTemplate({Test = 1}, true)
            expect(Test:Check({Test = 1})).to.equal(true)
            expect(Test:Check({Test = "1"})).to.equal(false)
            expect(Test:Check({Test = 1, Another = 2})).to.equal(false)
        end)

        it("should generate from objects: deep", function()
            local Test = TypeGuard.FromTemplate({Test = {Test = 35454535}})
            expect(Test:Check({Test = {}})).to.equal(false)
            expect(Test:Check({Test = {Test = 1}})).to.equal(true)
            expect(Test:Check({Test = {Test = "1"}})).to.equal(false)
        end)

        it("should generate strict objects: deep", function()
            local Test = TypeGuard.FromTemplate({Test = {Test = 1}}, true)
            expect(Test:Check({Test = {}})).to.equal(false)
            expect(Test:Check({Test = {Test = 1}})).to.equal(true)
            expect(Test:Check({Test = {Test = "1"}})).to.equal(false)
            expect(Test:Check({Test = {Test = 1, Another = 2}})).to.equal(false)
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
            local Serializer = Base:OfKeyType(String()):OfValueType(String())
            local Test = {Key1 = "Test1", Key2 = "Test2"}
            local Result = Serializer:OfStructure({
                Key1 = String();
                Key2 = String();
            }):Strict()

            for Key, Value in Test do
                expect(Result[Key]).to.equal(Value)
            end
        end)
    end)
end