local CollectionService = game:GetService("CollectionService")

local function anyfn(...) return ({} :: any) end
it = it or anyfn
expect = expect or anyfn
describe = describe or anyfn

return function()
    local TypeGuard = require(script.Parent)

    describe("CreateTemplate", function()
        it("should reject no Name given", function()
            expect(function()
                TypeGuard.CreateTemplate()
            end).to.throw()
        end)

        it("should reject incorrect types for Name", function()
            expect(function()
                TypeGuard.CreateTemplate(1)
            end).to.throw()

            expect(function()
                TypeGuard.CreateTemplate({})
            end).to.throw()

            expect(function()
                TypeGuard.CreateTemplate(true)
            end).to.throw()

            expect(function()
                TypeGuard.CreateTemplate("Test")
            end).never.to.throw()
        end)

        it("should return a constructor function and a TypeChecker class for extension", function()
            local TestCreate, TestClass = TypeGuard.CreateTemplate("Test")
            expect(TestCreate).to.be.a("function")
            expect(TestClass).to.be.a("table")
            expect(TestClass._TC).to.equal(true)
        end)
    end)

    describe("[One-Time vs Multiple-Time Constraints]", function()
        local Base = TypeGuard.Number()

        it("should allow a >1 time constraint if instantiated more than once on a checker", function()
            expect(function()
                Base:IsAKeyIn({}):IsAKeyIn({})
            end).never.to.throw()
        end)

        it("should correctly assess a >1 time constraint when instantiated more than once on a checker", function()
            local Checker = Base:IsAKeyIn({[123] = true, [456] = true}):IsAKeyIn({[456] = true, [789] = true})
            expect(Checker:Check(123)).to.equal(false)
            expect(Checker:Check(456)).to.equal(true)
            expect(Checker:Check(789)).to.equal(false)
        end)

        it("should reject a 1 time constraint if instantiated more than once on a checker", function()
            expect(function()
                Base:GreaterThan(3):GreaterThan(5)
            end).to.throw()
        end)
    end)

    describe("Params", function()
        it("should reject non-TypeChecker types", function()
            expect(function()
                TypeGuard.Params(1)
            end).to.throw()

            expect(function()
                TypeGuard.Params({})
            end).to.throw()

            expect(function()
                TypeGuard.Params(true)
            end).to.throw()
        end)

        it("should accept TypeChecker types", function()
            expect(function()
                TypeGuard.Params(TypeGuard.Number())
            end).never.to.throw()

            expect(function()
                TypeGuard.Params(TypeGuard.String())
            end).never.to.throw()

            expect(function()
                TypeGuard.Params(TypeGuard.Array())
            end).never.to.throw()
        end)

        it("should check one type", function()
            expect(function()
                TypeGuard.Params(TypeGuard.Number())(1)
            end).never.to.throw()

            expect(function()
                TypeGuard.Params(TypeGuard.Number())("Test")
            end).to.throw()
        end)

        it("should check multiple types", function()
            expect(function()
                TypeGuard.Params(TypeGuard.Number(), TypeGuard.String())(1, "Test")
            end).never.to.throw()

            expect(function()
                TypeGuard.Params(TypeGuard.Number(), TypeGuard.String())(1, 1)
            end).to.throw()
        end)
    end)

    describe("ParamsWithContext", function()
        it("should reject non-TypeChecker types", function()
            expect(function()
                TypeGuard.ParamsWithContext(1)
            end).to.throw()

            expect(function()
                TypeGuard.ParamsWithContext({})
            end).to.throw()

            expect(function()
                TypeGuard.ParamsWithContext(true)
            end).to.throw()
        end)

        it("should accept TypeChecker types", function()
            expect(function()
                TypeGuard.ParamsWithContext(TypeGuard.Number())
            end).never.to.throw()

            expect(function()
                TypeGuard.ParamsWithContext(TypeGuard.String())
            end).never.to.throw()

            expect(function()
                TypeGuard.ParamsWithContext(TypeGuard.Array())
            end).never.to.throw()
        end)

        it("should check one type", function()
            expect(function()
                TypeGuard.ParamsWithContext(TypeGuard.Number())(nil, 1)
            end).never.to.throw()

            expect(function()
                TypeGuard.ParamsWithContext(TypeGuard.Number())(nil, "Test")
            end).to.throw()
        end)

        it("should accept a context as first arg (or nil)", function()
            expect(function()
                TypeGuard.ParamsWithContext(TypeGuard.Number())("Test", 1)
            end).never.to.throw()

            expect(function()
                TypeGuard.ParamsWithContext(TypeGuard.Number())(nil, 1)
            end).never.to.throw()
        end)

        it("should pass the context down", function()
            expect(function()
                TypeGuard.ParamsWithContext(TypeGuard.Number():Equals(function(Context)
                    return Context.MustEqual
                end))({MustEqual = 1}, 1)
            end).never.to.throw()
        end)

        it("should check multiple types", function()
            expect(function()
                TypeGuard.ParamsWithContext(TypeGuard.Number(), TypeGuard.String())(nil, 1, "Test")
            end).never.to.throw()

            expect(function()
                TypeGuard.ParamsWithContext(TypeGuard.Number(), TypeGuard.String())(nil, 1, 1)
            end).to.throw()
        end)
    end)

    describe("Variadic", function()
        it("should reject non-TypeChecker types", function()
            expect(function()
                TypeGuard.Variadic(1)
            end).to.throw()

            expect(function()
                TypeGuard.Variadic({})
            end).to.throw()

            expect(function()
                TypeGuard.Variadic(true)
            end).to.throw()
        end)

        it("should accept TypeChecker types", function()
            expect(function()
                TypeGuard.Variadic(TypeGuard.Number())
            end).never.to.throw()

            expect(function()
                TypeGuard.Variadic(TypeGuard.String())
            end).never.to.throw()

            expect(function()
                TypeGuard.Variadic(TypeGuard.Array())
            end).never.to.throw()
        end)

        it("should check one type", function()
            expect(function()
                TypeGuard.Variadic(TypeGuard.Number())(1)
            end).never.to.throw()

            expect(function()
                TypeGuard.Variadic(TypeGuard.Number())("Test")
            end).to.throw()
        end)

        it("should check multiple types", function()
            expect(function()
                TypeGuard.Variadic(TypeGuard.Number())(1, 1)
            end).never.to.throw()

            expect(function()
                TypeGuard.Variadic(TypeGuard.Number())(1, "Test")
            end).to.throw()
        end)
    end)

    describe("VariadicWithContext", function()
        it("should reject non-TypeChecker types", function()
            expect(function()
                TypeGuard.VariadicWithContext(1)
            end).to.throw()

            expect(function()
                TypeGuard.VariadicWithContext({})
            end).to.throw()

            expect(function()
                TypeGuard.VariadicWithContext(true)
            end).to.throw()
        end)

        it("should accept TypeChecker types", function()
            expect(function()
                TypeGuard.VariadicWithContext(TypeGuard.Number())
            end).never.to.throw()

            expect(function()
                TypeGuard.VariadicWithContext(TypeGuard.String())
            end).never.to.throw()

            expect(function()
                TypeGuard.VariadicWithContext(TypeGuard.Array())
            end).never.to.throw()
        end)

        it("should check one type", function()
            expect(function()
                TypeGuard.VariadicWithContext(TypeGuard.Number())(nil, 1)
            end).never.to.throw()

            expect(function()
                TypeGuard.VariadicWithContext(TypeGuard.Number())(nil, "Test")
            end).to.throw()
        end)

        it("should accept a context as first arg (or nil)", function()
            expect(function()
                TypeGuard.VariadicWithContext(TypeGuard.Number())("Test", 1, 1, 1)
            end).never.to.throw()

            expect(function()
                TypeGuard.VariadicWithContext(TypeGuard.Number())(nil, 1, 1, 1)
            end).never.to.throw()
        end)

        it("should pass the context down", function()
            expect(function()
                TypeGuard.VariadicWithContext(TypeGuard.Number():Equals(function(Context)
                    return Context.MustEqual
                end))({MustEqual = 1}, 1, 1, 1)
            end).never.to.throw()

            expect(function()
                TypeGuard.VariadicWithContext(TypeGuard.Number():Equals(function(Context)
                    return Context.MustEqual
                end))({MustEqual = 1}, 1, 1, 2)
            end).to.throw()
        end)

        it("should check multiple types", function()
            expect(function()
                TypeGuard.VariadicWithContext(TypeGuard.Number())(nil, 1, 1)
            end).never.to.throw()

            expect(function()
                TypeGuard.VariadicWithContext(TypeGuard.Number())(nil, 1, "Test")
            end).to.throw()
        end)
    end)

    -- These behaviors extend to all TypeChecker implementations
    describe("TypeChecker", function()
        describe("Optional", function()
            it("should accept nil as a checked value", function()
                expect(TypeGuard.Number():Optional():Check(nil)).to.equal(true)
            end)

            it("should accept the target constraint as a checked value if not nil", function()
                expect(TypeGuard.Number():Optional():Check(1)).to.equal(true)
                expect(TypeGuard.Number():Optional():Check("Test")).to.equal(false)
            end)
        end)

        describe("Alias", function()
            it("should reject non-string args", function()
                expect(function()
                    TypeGuard.Number():Alias(1)
                end).to.throw()

                expect(function()
                    TypeGuard.Number():Alias({})
                end).to.throw()

                expect(function()
                    TypeGuard.Number():Alias(true)
                end).to.throw()
            end)

            it("should accept string args", function()
                expect(function()
                    TypeGuard.Number():Alias("Test")
                end).never.to.throw()
            end)

            it("should give a fail string with the alias", function()
                local _, Result = TypeGuard.Number():Or(TypeGuard.Array()):Alias("TestAlias"):Check("Test")
                expect(Result).to.be.a("string")
                expect(Result:match("TestAlias")).to.be.ok()
            end)
        end)

        describe("Or", function()
            it("should reject non-TypeChecker args", function()
                expect(function()
                    TypeGuard.Number():Or(1)
                end).to.throw()

                expect(function()
                    TypeGuard.Number():Or({})
                end).to.throw()

                expect(function()
                    TypeGuard.Number():Or(true)
                end).to.throw()
            end)

            it("should accept TypeChecker args", function()
                expect(function()
                    TypeGuard.Number():Or(TypeGuard.Number())
                end).never.to.throw()

                expect(function()
                    TypeGuard.Number():Or(TypeGuard.String())
                end).never.to.throw()

                expect(function()
                    TypeGuard.Number():Or(TypeGuard.Array())
                end).never.to.throw()
            end)

            it("should accept function args", function()
                expect(function()
                    TypeGuard.Number():Or(function() end)
                end).never.to.throw()
            end)

            it("should accept inputs if they satisfy a TypeChecker in the or chain", function()
                local Check = TypeGuard.Number():Or(TypeGuard.Boolean())
                expect(Check:Check(1)).to.equal(true)
                expect(Check:Check(true)).to.equal(true)
                expect(Check:Check(false)).to.equal(true)
            end)

            it("should reject inputs if they do not satisfy a TypeChecker in the or chain", function()
                local Check = TypeGuard.Number():Or(TypeGuard.Boolean())
                expect(Check:Check("Test")).to.equal(false)
                expect(Check:Check({})).to.equal(false)
            end)

            it("should accept functional inputs if they return a TypeChecker which satisfies the or chain", function()
                local Check = TypeGuard.Number():Or(function() return TypeGuard.Boolean() end)
                expect(Check:Check(1)).to.equal(true)
                expect(Check:Check(true)).to.equal(true)
                expect(Check:Check(false)).to.equal(true)
            end)

            it("should reject functional inputs if they return a TypeChecker which does not satisfy the or chain", function()
                local Check = TypeGuard.Number():Or(function() return TypeGuard.Boolean() end)
                expect(Check:Check("Test")).to.equal(false)
                expect(Check:Check({})).to.equal(false)
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

        describe("Check", function()
            it("should return a true boolean and no string on success", function()
                local Check = TypeGuard.Number()
                local Result, Error = Check:Check(1)
                expect(Result).to.be.a("boolean")
                expect(Result).to.equal(true)
                expect(Error).to.equal(nil)
            end)

            it("should return a false boolean and a fail string on failure", function()
                local Check = TypeGuard.Number()
                local Result, Error = Check:Check("Test")
                expect(Result).to.be.a("boolean")
                expect(Result).to.equal(false)
                expect(Error).to.be.a("string")
                expect(Error).never.to.equal("")
            end)
        end)

        describe("Cached", function()
            it("should cache results if Cached is used on simple types", function()
                local Check = TypeGuard.Number():Cached()
                expect(Check:Check(1)).to.equal(true)
                expect(Check:Check(1)).to.equal(true)
            end)

            it("should cache results if Cached is used on complex types", function()
                local Check = TypeGuard.Object():OfStructure({X = TypeGuard.Number()}):Strict():Cached()
                local Test = {X = 1}
                expect(Check:Check(Test)).to.equal(true)
                Test.Y = 2
                expect(Check:Check(Test)).to.equal(true) -- Technically incorrect but that's the cost of caching: performance increase for temporal correctness
                expect(Check:Check({X = 1})).to.equal(true)
            end)
        end)

        describe("AsPredicate", function()
            it("should return a function", function()
                expect(TypeGuard.Number():AsPredicate()).to.be.a("function")
            end)

            it("should call Check directly and pass a boolean & status string", function()
                local Check = TypeGuard.Number():AsPredicate()
                local Result, Error = Check(1)
                expect(Result).to.be.a("boolean")
                expect(Result).to.equal(true)
                expect(Error).to.equal(nil)

                local Result2, Error2 = Check("Test")
                expect(Result2).to.be.a("boolean")
                expect(Result2).to.equal(false)
                expect(Error2).to.be.a("string")
                expect(Error2).never.to.equal("")
            end)
        end)

        describe("Assert", function()
            it("should not throw when the type is satisfied", function()
                expect(function()
                    TypeGuard.Number():Assert(1)
                end).never.to.throw()
            end)

            it("should throw when the type is unsatisfied, giving the status string", function()
                local Input = "Test"
                local _, CheckResult = TypeGuard.Number():Check(Input)

                expect(function()
                    TypeGuard.Number():Assert(Input)
                end).to.throw(CheckResult)
            end)
        end)

        describe("AsAssertion", function()
            it("should return a function", function()
                expect(TypeGuard.Number():AsAssertion()).to.be.a("function")
            end)

            it("should call Assert directly and pass a boolean & status string", function()
                local Input = 1

                local _, CheckResult = TypeGuard.Number():Check(Input)
                local AssertFunction = TypeGuard.Number():AsAssertion()

                expect(function()
                    AssertFunction(Input)
                end).never.to.throw()

                expect(function()
                    AssertFunction("Test")
                end).to.throw(CheckResult)
            end)
        end)

        describe("Negate", function()
            it("should throw an exception if there are no constraints", function()
                expect(function()
                    TypeGuard.Number():Negate()
                end).to.throw()
            end)

            it("should invert the result of the TypeChecker", function()
                local Check = TypeGuard.Number():Equals(5):Negate()
                expect(Check:Check(1)).to.equal(true)
                expect(Check:Check(5)).to.equal(false)
                expect(Check:Check(10)).to.equal(true)
            end)

            it("should invert only the last constraint", function()
                local Check = TypeGuard.Number():GreaterThan(1):Equals(10):Negate()
                expect(Check:Check(2)).to.equal(true)
                expect(Check:Check(10)).to.equal(false)
                expect(Check:Check(20)).to.equal(true)
            end)
        end)

        describe("WithContext", function()
            it("should accept any value", function()
                expect(function()
                    TypeGuard.Number():WithContext("Test")
                end).never.to.throw()

                expect(function()
                    TypeGuard.Number():WithContext(1)
                end).never.to.throw()

                expect(function()
                    TypeGuard.Number():WithContext(true)
                end).never.to.throw()

                expect(function()
                    TypeGuard.Number():WithContext(false)
                end).never.to.throw()

                expect(function()
                    TypeGuard.Number():WithContext(nil)
                end).never.to.throw()

                expect(function()
                    TypeGuard.Number():WithContext(Instance.new("Folder"))
                end).never.to.throw()

                expect(function()
                    TypeGuard.Number():WithContext({X = 1, Y = 2})
                end).never.to.throw()
            end)

            it("should pass the context to constraints", function()
                local DidRun = false
                local Check = TypeGuard.Number():WithContext("Test"):Equals(function(Context)
                    DidRun = true
                    expect(Context).to.equal("Test")
                    return 1
                end)

                expect(Check:Check(1)).to.equal(true)
                expect(DidRun).to.equal(true)
            end)

            it("should pass the root context down even if a new context is given mid-way", function()
                local DidRun = false
                local Check = TypeGuard.Object():WithContext("Test0"):OfStructure({
                    X = TypeGuard.Object():WithContext("Test1"):OfStructure({
                        Y = TypeGuard.Number():WithContext("Test2"):Equals(function(Context)
                            DidRun = true
                            expect(Context).to.equal("Test0")
                            return 1
                        end)
                    });
                })

                expect(Check:Check({
                    X = {
                        Y = 1;
                    }
                })).to.equal(true)
                expect(DidRun).to.equal(true)
            end)
        end)

        describe("FailMessage", function()
            it("should reject non-string args", function()
                expect(function()
                    TypeGuard.Number():FailMessage(1)
                end).to.throw()

                expect(function()
                    TypeGuard.Number():FailMessage(true)
                end).to.throw()

                expect(function()
                    TypeGuard.Number():FailMessage(false)
                end).to.throw()

                expect(function()
                    TypeGuard.Number():FailMessage(nil)
                end).to.throw()

                expect(function()
                    TypeGuard.Number():FailMessage({})
                end).to.throw()
            end)

            it("should accept string args", function()
                expect(function()
                    TypeGuard.Number():FailMessage("Test")
                end).never.to.throw()
            end)

            it("should enforce a custom fail message on failure", function()
                local Check = TypeGuard.Number():FailMessage("0123456789")
                local _, Error = Check:Check("Test")
                expect(Error).to.equal("0123456789")
            end)

            it("should work with Or calls", function()
                local Check = TypeGuard.Number():Or(TypeGuard.Array()):FailMessage("0123456789")
                local _, Error = Check:Check("Test")
                expect(Error).to.equal("0123456789")
            end)

            it("should work with And calls", function()
                local Check = TypeGuard.Number():And(TypeGuard.Array()):FailMessage("0123456789")
                local _, Error = Check:Check("Test")
                expect(Error).to.equal("0123456789")
            end)

            it("should work with Cached calls", function()
                local Check = TypeGuard.Number():Cached():FailMessage("0123456789")

                local _, Error = Check:Check("Test")
                expect(Error).to.equal("0123456789")

                local _, Again = Check:Check("Test")
                expect(Again).to.equal("0123456789")
            end)

            it("should still exist with subsequent constraint calls", function()
                local Check = TypeGuard.Number():FailMessage("0123456789"):RangeInclusive(0, 10):Decimal()
                local _, Error = Check:Check(1000)
                expect(Error).to.equal("0123456789")
            end)
        end)
    end)
end