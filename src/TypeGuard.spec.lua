-- WIP

return function()
    local TypeGuard = require(script.Parent)

    describe("Template", function()
        it("should reject no Name given", function()
            expect(function()
                TypeGuard.Template()
            end).to.throw()
        end)

        it("should reject incorrect types for Name", function()
            expect(function()
                TypeGuard.Template(1)
            end).to.throw()

            expect(function()
                TypeGuard.Template({})
            end).to.throw()

            expect(function()
                TypeGuard.Template(true)
            end).to.throw()

            expect(function()
                TypeGuard.Template("Test")
            end).never.to.throw()
        end)

        it("should return a constructor function and a TypeChecker class for extension", function()
            local TestCreate, TestClass = TypeGuard.Template("Test")
            expect(TestCreate).to.be.a("function")
            expect(TestClass).to.be.a("table")
            expect(TestClass._IsTemplate).to.equal(true)
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

    describe("VariadicParams", function()
        it("should reject non-TypeChecker types", function()
            expect(function()
                TypeGuard.VariadicParams(1)
            end).to.throw()

            expect(function()
                TypeGuard.VariadicParams({})
            end).to.throw()

            expect(function()
                TypeGuard.VariadicParams(true)
            end).to.throw()
        end)

        it("should accept TypeChecker types", function()
            expect(function()
                TypeGuard.VariadicParams(TypeGuard.Number())
            end).never.to.throw()

            expect(function()
                TypeGuard.VariadicParams(TypeGuard.String())
            end).never.to.throw()

            expect(function()
                TypeGuard.VariadicParams(TypeGuard.Array())
            end).never.to.throw()
        end)

        it("should check one type", function()
            expect(function()
                TypeGuard.VariadicParams(TypeGuard.Number())(1)
            end).never.to.throw()

            expect(function()
                TypeGuard.VariadicParams(TypeGuard.Number())("Test")
            end).to.throw()
        end)

        it("should check multiple types", function()
            expect(function()
                TypeGuard.VariadicParams(TypeGuard.Number())(1, 1)
            end).never.to.throw()

            expect(function()
                TypeGuard.VariadicParams(TypeGuard.Number())(1, "Test")
            end).to.throw()
        end)
    end)

    describe("WrapFunctionParams", function()
        it("should reject non functions as first arg", function()
            expect(function()
                TypeGuard.WrapFunctionParams(1)
            end).to.throw()

            expect(function()
                TypeGuard.WrapFunctionParams({})
            end).to.throw()

            expect(function()
                TypeGuard.WrapFunctionParams(true)
            end).to.throw()

            expect(function()
                TypeGuard.WrapFunctionParams(function() end)
            end).never.to.throw()
        end)

        it("should reject non-TypeChecker types", function()
            expect(function()
                TypeGuard.WrapFunctionParams(function() end, 1)
            end).to.throw()

            expect(function()
                TypeGuard.WrapFunctionParams(function() end, {})
            end).to.throw()

            expect(function()
                TypeGuard.WrapFunctionParams(function() end, true)
            end).to.throw()
        end)

        it("should accept TypeChecker types", function()
            expect(function()
                TypeGuard.WrapFunctionParams(function() end, TypeGuard.Number())
            end).never.to.throw()

            expect(function()
                TypeGuard.WrapFunctionParams(function() end, TypeGuard.String())
            end).never.to.throw()

            expect(function()
                TypeGuard.WrapFunctionParams(function() end, TypeGuard.Array())
            end).never.to.throw()
        end)

        it("should wrap a function", function()
            local function TestFunction(_X, _Y, _Z) end

            local TestWrapped = TypeGuard.WrapFunctionParams(TestFunction, TypeGuard.Number(), TypeGuard.String(), TypeGuard.Boolean())
            expect(TestWrapped).to.be.a("function")

            expect(function()
                TestWrapped(1, "x", true)
            end).never.to.throw()

            expect(function()
                TestWrapped(1, "x", "y")
            end).to.throw()

            expect(function()
                TestWrapped(1, "x", true, "y")
            end).to.throw()

            expect(function()
                TestWrapped("1", "x", true)
            end).to.throw()
        end)
    end)

    describe("WrapFunctionVariadicParams", function()
        it("should reject non functions as first arg", function()
            expect(function()
                TypeGuard.WrapFunctionVariadicParams(1)
            end).to.throw()

            expect(function()
                TypeGuard.WrapFunctionVariadicParams({})
            end).to.throw()

            expect(function()
                TypeGuard.WrapFunctionVariadicParams(true)
            end).to.throw()

            expect(function()
                TypeGuard.WrapFunctionVariadicParams(function() end, TypeGuard.Number())
            end).never.to.throw()
        end)

        it("should reject non-TypeChecker types", function()
            expect(function()
                TypeGuard.WrapFunctionVariadicParams(function() end, 1)
            end).to.throw()

            expect(function()
                TypeGuard.WrapFunctionVariadicParams(function() end, {})
            end).to.throw()

            expect(function()
                TypeGuard.WrapFunctionVariadicParams(function() end, true)
            end).to.throw()
        end)

        it("should accept TypeChecker types", function()
            expect(function()
                TypeGuard.WrapFunctionVariadicParams(function() end, TypeGuard.Number())
            end).never.to.throw()

            expect(function()
                TypeGuard.WrapFunctionVariadicParams(function() end, TypeGuard.String())
            end).never.to.throw()

            expect(function()
                TypeGuard.WrapFunctionVariadicParams(function() end, TypeGuard.Array())
            end).never.to.throw()
        end)

        it("should wrap a function", function()
            local function TestFunction(_X, ...) end

            local TestWrapped = TypeGuard.WrapFunctionVariadicParams(TestFunction, TypeGuard.Number())
            expect(TestWrapped).to.be.a("function")

            expect(function()
                TestWrapped(1)
            end).never.to.throw()

            expect(function()
                TestWrapped(1, "x")
            end).to.throw()

            expect(function()
                TestWrapped(1, "x", true)
            end).to.throw()

            expect(function()
                TestWrapped(9, 8, 7, 6, 5, 4, 3, 2, 1)
            end).never.to.throw()
        end)
    end)

    -- These behaviors extend to all type checker implementations
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
            it("should return a true boolean and an empty string on success", function()
                local Check = TypeGuard.Number()
                local Result, Error = Check:Check(1)
                expect(Result).to.be.a("boolean")
                expect(Result).to.equal(true)
                expect(Error).to.be.a("string")
                expect(Error).to.equal("")
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
        describe("WrapCheck", function()
            it("should return a function", function()
                expect(TypeGuard.Number():WrapCheck()).to.be.a("function")
            end)

            it("should call Check directly and pass a boolean & status string", function()
                local Check = TypeGuard.Number():WrapCheck()
                local Result, Error = Check(1)
                expect(Result).to.be.a("boolean")
                expect(Result).to.equal(true)
                expect(Error).to.be.a("string")
                expect(Error).to.equal("")

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
        describe("WrapAssert", function()
            it("should return a function", function()
                expect(TypeGuard.Number():WrapAssert()).to.be.a("function")
            end)

            it("should call Assert directly and pass a boolean & status string", function()
                local Input = 1

                local _, CheckResult = TypeGuard.Number():Check(Input)
                local AssertFunction = TypeGuard.Number():WrapAssert()

                expect(function()
                    AssertFunction(Input)
                end).never.to.throw()

                expect(function()
                    AssertFunction("Test")
                end).to.throw(CheckResult)
            end)
        end)
    end)

    describe("Number", function()
        local Base = TypeGuard.Number()

        describe("Init", function()
            it("should reject non-numbers", function()
                expect(Base:Check("Test")).to.equal(false)
                expect(Base:Check(true)).to.equal(false)
                expect(Base:Check(function() end)).to.equal(false)
                expect(Base:Check(nil)).to.equal(false)
                expect(Base:Check({})).to.equal(false)
            end)

            it("should accept numbers", function()
                expect(Base:Check(1)).to.equal(true)
                expect(Base:Check(1.1)).to.equal(true)
                expect(Base:Check(0)).to.equal(true)
                expect(Base:Check(-1)).to.equal(true)
                expect(Base:Check(-1.1)).to.equal(true)
            end)
        end)

        describe("Integer", function()
            it("should reject non-integers", function()
                expect(Base:Integer():Check(1.1)).to.equal(false)
            end)

            it("should accept integers", function()
                expect(Base:Integer():Check(1)).to.equal(true)
            end)

            it("should accept negative integers", function()
                expect(Base:Integer():Check(-1)).to.equal(true)
            end)

            it("should reject non-numbers", function()
                expect(Base:Integer():Check("Test")).to.equal(false)
            end)
        end)

        describe("Decimal", function()
            it("should reject non-decimals", function()
                expect(Base:Decimal():Check(1)).to.equal(false)
            end)

            it("should accept decimals", function()
                expect(Base:Decimal():Check(1.1)).to.equal(true)
            end)

            it("should accept negative decimals", function()
                expect(Base:Decimal():Check(-1.1)).to.equal(true)
            end)

            it("should reject non-numbers", function()
                expect(Base:Decimal():Check("Test")).to.equal(false)
            end)
        end)

        describe("RangeInclusive", function()
            it("should reject non-numbers", function()
                expect(Base:RangeInclusive(1, 2):Check("Test")).to.equal(false)
            end)

            it("should reject numbers outside of range", function()
                expect(Base:RangeInclusive(1, 2):Check(0)).to.equal(false)
                expect(Base:RangeInclusive(1, 2):Check(3)).to.equal(false)
            end)

            it("should accept numbers inside of range", function()
                expect(Base:RangeInclusive(1, 2):Check(1)).to.equal(true)
                expect(Base:RangeInclusive(1, 2):Check(2)).to.equal(true)
            end)

            it("should accept numbers equal to the range bounds", function()
                expect(Base:RangeInclusive(1, 2):Check(1)).to.equal(true)
                expect(Base:RangeInclusive(1, 2):Check(2)).to.equal(true)
            end)
        end)

        describe("RangeExclusive", function()
            it("should reject non-numbers", function()
                expect(Base:RangeExclusive(1, 2):Check("Test")).to.equal(false)
            end)

            it("should reject numbers outside of range", function()
                expect(Base:RangeExclusive(1, 2):Check(0)).to.equal(false)
                expect(Base:RangeExclusive(1, 2):Check(3)).to.equal(false)
            end)

            it("should accept numbers inside of range", function()
                expect(Base:RangeExclusive(1, 2):Check(1.1)).to.equal(true)
                expect(Base:RangeExclusive(1, 2):Check(1.9)).to.equal(true)
            end)

            it("should reject numbers equal to the range bounds", function()
                expect(Base:RangeExclusive(1, 2):Check(1)).to.equal(false)
                expect(Base:RangeExclusive(1, 2):Check(2)).to.equal(false)
            end)
        end)

        describe("Positive", function()
            it("should reject non-numbers", function()
                expect(Base:Positive():Check("Test")).to.equal(false)
            end)

            it("should reject negative numbers", function()
                expect(Base:Positive():Check(-1)).to.equal(false)
            end)

            it("should accept positive numbers", function()
                expect(Base:Positive():Check(0)).to.equal(true)
                expect(Base:Positive():Check(1)).to.equal(true)
            end)
        end)

        describe("Negative", function()
            it("should reject non-numbers", function()
                expect(Base:Negative():Check("Test")).to.equal(false)
            end)

            it("should reject positive numbers", function()
                expect(Base:Negative():Check(0)).to.equal(false)
                expect(Base:Negative():Check(1)).to.equal(false)
            end)

            it("should accept negative numbers", function()
                expect(Base:Negative():Check(-1)).to.equal(true)
            end)
        end)

        describe("Equals", function()
            it("should reject non equal inputs", function()
                expect(Base:Equals(1):Check(2)).to.equal(false)
            end)

            it("should accept equal inputs", function()
                expect(Base:Equals(1):Check(1)).to.equal(true)
            end)
        end)

        describe("GreaterThan", function()
            it("should reject numbers less than the first arg", function()
                expect(Base:GreaterThan(1):Check(0)).to.equal(false)
            end)

            it("should accept numbers greater than the first arg", function()
                expect(Base:GreaterThan(1):Check(2)).to.equal(true)
            end)
        end)

        describe("IsAKeyIn", function()
            it("should reject a non table as first arg", function()
                expect(function()
                    Base:IsAKeyIn(1)
                end).to.throw()

                expect(function()
                    Base:IsAKeyIn("Test")
                end).to.throw()

                expect(function()
                    Base:IsAKeyIn(true)
                end).to.throw()
            end)

            it("should accept a table as first arg", function()
                expect(function()
                    Base:IsAKeyIn({})
                end).never.to.throw()
            end)

            it("should reject when the value does not exist as a key", function()
                expect(Base:IsAKeyIn({}):Check(123)).to.equal(false)
            end)

            it("should accept when the value does exist as a key", function()
                expect(Base:IsAKeyIn({[123] = true}):Check(123)).to.equal(true)
            end)
        end)

        describe("IsAValueIn", function()
            it("should reject a non table as first arg", function()
                expect(function()
                    Base:IsAValueIn(1)
                end).to.throw()

                expect(function()
                    Base:IsAValueIn("Test")
                end).to.throw()

                expect(function()
                    Base:IsAValueIn(true)
                end).to.throw()
            end)

            it("should accept a table as first arg", function()
                expect(function()
                    Base:IsAValueIn({})
                end).never.to.throw()
            end)

            it("should reject when the value does not exist in an array", function()
                expect(Base:IsAValueIn({}):Check(123)).to.equal(false)
            end)

            it("should accept when the value exists in an array", function()
                expect(Base:IsAValueIn({123}):Check(123)).to.equal(true)
            end)
        end)
    end)

    describe("Boolean", function()
        local Base = TypeGuard.Boolean()

        describe("Init", function()
            it("should reject non-booleans", function()
                expect(Base:Check("Test")).to.equal(false)
                expect(Base:Check(1)).to.equal(false)
                expect(Base:Check(function() end)).to.equal(false)
                expect(Base:Check(nil)).to.equal(false)
                expect(Base:Check({})).to.equal(false)
            end)

            it("should accept booleans", function()
                expect(Base:Check(true)).to.equal(true)
                expect(Base:Check(false)).to.equal(true)
            end)
        end)
    end)

    describe("Instance", function()
        local Base = TypeGuard.Instance()

        describe("Init", function()
            it("should reject non-Instances", function()
                expect(Base:Check("Test")).to.equal(false)
                expect(Base:Check(1)).to.equal(false)
                expect(Base:Check(function() end)).to.equal(false)
                expect(Base:Check(nil)).to.equal(false)
                expect(Base:Check({})).to.equal(false)
            end)

            it("should accept Instances", function()
                expect(Base:Check(Instance.new("Model"))).to.equal(true)
            end)

            it("should use the IsA constraint as the initial constraint", function()
                local Test = TypeGuard.Instance("Model")

                expect(Test:Check(Instance.new("Model"))).to.equal(true)
                expect(Test:Check(Instance.new("Part"))).to.equal(false)
            end)
        end)

        describe("IsA", function()
            it("should reject non-Instances", function()
                expect(Base:IsA("Folder"):Check("Folder")).to.equal(false)
                expect(Base:IsA("Folder"):Check(1)).to.equal(false)
                expect(Base:IsA("Folder"):Check(function() end)).to.equal(false)
                expect(Base:IsA("Folder"):Check(nil)).to.equal(false)
                expect(Base:IsA("Folder"):Check({})).to.equal(false)
            end)

            it("should accept Instances", function()
                expect(Base:IsA("Folder"):Check(Instance.new("Folder"))).to.equal(true)
            end)

            it("should accept Instances of the specified class", function()
                expect(Base:IsA("Folder"):Check(Instance.new("Folder"))).to.equal(true)
            end)

            it("should reject Instances of other classes", function()
                expect(Base:IsA("Folder"):Check(Instance.new("Part"))).to.equal(false)
            end)
        end)

        describe("OfStructure", function()
            it("should reject non-Instances", function()
                expect(function()
                    Base:OfStructure({Test = "Test"})
                end).to.throw()

                expect(function()
                    Base:OfStructure({Test = 1})
                end).to.throw()

                expect(function()
                    Base:OfStructure({Test = function() end})
                end).to.throw()
            end)

            it("should accept a map of children and/or properties", function()
                expect(function()
                    Base:OfStructure({
                        Test = TypeGuard.Instance("Folder");
                        Name = TypeGuard.String();
                    })
                end).to.never.throw()
            end)

            it("should reject Instances that do not match the structure", function()
                expect(
                    Base:OfStructure({
                        Test = TypeGuard.Instance("Folder");
                        Name = TypeGuard.String();
                    }):Check(Instance.new("Folder"))
                ).to.equal(false)
            end)

            it("should accept Instances that match the structure", function()
                local SampleTree = Instance.new("Folder")
                    local Test = Instance.new("Folder", SampleTree)
                    Test.Name = "Test"

                expect(
                    Base:OfStructure({
                        Test = TypeGuard.Instance("Folder");
                        Name = TypeGuard.String();
                    }):Check(SampleTree)
                ).to.equal(true)
            end)

            it("should reject Instances that do not match the structure recursively", function()
                local SampleTree = Instance.new("Folder")
                    local Test = Instance.new("Folder", SampleTree)
                    Test.Name = "Test"
                        local Test2 = Instance.new("Part", Test)
                        Test2.Name = "Test2"

                expect(
                    Base:OfStructure({
                        Test = TypeGuard.Instance("Folder"):OfStructure({
                            Test2 = TypeGuard.Instance():OfStructure({
                                Name = TypeGuard.String():Equals("Incorrect Name");
                            });
                            Name = TypeGuard.String():Equals("Test");
                        });
                        Name = TypeGuard.String():Equals("Folder");
                    }):Check(Test)
                ).to.equal(false)
            end)

            it("should accept Instances that match the structure recursively", function()
                local SampleTree = Instance.new("Folder")
                    local Test = Instance.new("Folder", SampleTree)
                    Test.Name = "Test"
                        local Test2 = Instance.new("Part", Test)
                        Test2.Name = "Test2"

                expect(
                    Base:OfStructure({
                        Test = TypeGuard.Instance("Folder"):OfStructure({
                            Test2 = TypeGuard.Instance():OfStructure({
                                Name = TypeGuard.String():Equals("Test2");
                            });
                            Name = TypeGuard.String():Equals("Test");
                        });
                        Name = TypeGuard.String():Equals("Folder");
                    }):Check(Test)
                ).to.equal(false)
            end)
        end)

        describe("StructuralEquals (Strict + OfStructure)", function()
            it("should reject extra flat children", function()
                local SampleTree = Instance.new("Folder")
                    local Test = Instance.new("Folder", SampleTree)
                    Test.Name = "Test"
                    local Test2 = Instance.new("Folder", SampleTree)
                    Test2.Name = "Test2"

                expect(
                    Base:StructuralEquals({
                        Test = TypeGuard.Instance("Folder");
                    }):Check(SampleTree)
                ).to.equal(false)

                expect(
                    Base:StructuralEquals({
                        Test = TypeGuard.Instance("Folder");
                        Test2 = TypeGuard.Instance("Folder");
                    }):Check(SampleTree)
                ).to.equal(true)
            end)

            it("should reject extra children recursively", function()
                local SampleTree = Instance.new("Folder")
                    local Test = Instance.new("Folder", SampleTree)
                    Test.Name = "Test"
                        local Test2 = Instance.new("Folder", Test)
                        Test2.Name = "Test2"
                        local Test22 = Instance.new("Folder", Test)
                        Test22.Name = "Test22"

                expect(
                    Base:StructuralEquals({
                        Test = TypeGuard.Instance("Folder"):StructuralEquals({
                            Test2 = TypeGuard.Instance("Folder");
                            -- No Test22, should reject
                        });
                    }):Check(SampleTree)
                ).to.equal(false)

                expect(
                    Base:StructuralEquals({
                        Test = TypeGuard.Instance("Folder"):StructuralEquals({
                            Test2 = TypeGuard.Instance("Folder");
                            Test22 = TypeGuard.Instance("Folder");
                        });
                    }):Check(SampleTree)
                ).to.equal(true)
            end)
        end)
    end)

    describe("String", function()
        local Base = TypeGuard.String()

        describe("Init", function()
            it("should accept a string", function()
                expect(Base:Check("Test")).to.equal(true)
            end)

            it("should reject non-strings", function()
                expect(Base:Check(1)).to.equal(false)
                expect(Base:Check(function() end)).to.equal(false)
                expect(Base:Check(nil)).to.equal(false)
                expect(Base:Check({})).to.equal(false)
            end)
        end)

        describe("MinLength", function()
            it("should reject strings shorter than the specified length", function()
                expect(Base:MinLength(5):Check("Test")).to.equal(false)
            end)

            it("should accept strings longer than the specified length", function()
                expect(Base:MinLength(5):Check("Test123")).to.equal(true)
            end)

            it("should accept strings equal to the specified length", function()
                expect(Base:MinLength(5):Check("12345")).to.equal(true)
            end)
        end)

        describe("MaxLength", function()
            it("should reject strings longer than the specified length", function()
                expect(Base:MaxLength(5):Check("Test123")).to.equal(false)
            end)

            it("should accept strings shorter than the specified length", function()
                expect(Base:MaxLength(5):Check("Test")).to.equal(true)
            end)

            it("should accept strings equal to the specified length", function()
                expect(Base:MaxLength(5):Check("12345")).to.equal(true)
            end)
        end)

        describe("Pattern", function()
            it("should accept strings matching the specified pattern", function()
                expect(Base:Pattern("[0-9]+"):Check("34789275")).to.equal(true)
            end)

            it("should reject strings not matching the specified pattern", function()
                expect(Base:Pattern("[0-9]+"):Check("123h4")).to.equal(false)
            end)
        end)

        describe("Contains", function()
            it("should accept strings containing the specified substring", function()
                expect(Base:Contains("Test"):Check("------Test123")).to.equal(true)
            end)

            it("should reject strings not containing the specified substring", function()
                expect(Base:Contains("Test"):Check("asdfghjkl")).to.equal(false)
            end)
        end)
    end)

    describe("Array", function()
        local Base = TypeGuard.Array()

        describe("Init", function()
            it("should accept an array", function()
                expect(Base:Check({})).to.equal(true)
                expect(Base:Check({1})).to.equal(true)
                expect(Base:Check({1, 2})).to.equal(true)
            end)

            it("should reject non-arrays", function()
                expect(Base:Check(1)).to.equal(false)
                expect(Base:Check(function() end)).to.equal(false)
                expect(Base:Check(nil)).to.equal(false)
                expect(Base:Check({Test = true})).to.equal(false)
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
        end)

        describe("MinLength", function()
            it("should reject arrays shorter than the specified length", function()
                expect(Base:MinLength(5):Check({1, 2, 3, 4})).to.equal(false)
            end)

            it("should accept arrays equal to the specified length", function()
                expect(Base:MinLength(5):Check({1, 2, 3, 4, 5})).to.equal(true)
            end)

            it("should accept arrays longer than the specified length", function()
                expect(Base:MinLength(5):Check({1, 2, 3, 4, 5, 6})).to.equal(true)
            end)
        end)

        describe("MaxLength", function()
            it("should reject arrays longer than the specified length", function()
                expect(Base:MaxLength(5):Check({1, 2, 3, 4, 5, 6})).to.equal(false)
            end)

            it("should accept arrays equal to the specified length", function()
                expect(Base:MaxLength(5):Check({1, 2, 3, 4, 5})).to.equal(true)
            end)

            it("should accept arrays shorter than the specified length", function()
                expect(Base:MaxLength(5):Check({1, 2, 3, 4})).to.equal(true)
            end)
        end)

        describe("Contains", function()
            it("should accept arrays containing the specified element", function()
                expect(Base:Contains(1):Check({1, 2, 3, 4})).to.equal(true)
            end)

            it("should reject arrays not containing the specified element", function()
                expect(Base:Contains(1):Check({2, 3, 4})).to.equal(false)
            end)
        end)

        describe("OfType", function()
            it("should accept arrays containing only the specified type", function()
                expect(Base:OfType(TypeGuard.Number()):Check({1, 2, 3, 4})).to.equal(true)
            end)

            it("should reject arrays containing elements of other types", function()
                expect(Base:OfType(TypeGuard.Number()):Check({1, "Test", 3, 4})).to.equal(false)
            end)
        end)

        describe("OfStructure", function()
            it("should throw for non type checkers inside the template array", function()
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

            it("should not throw for type checkers inside the template array", function()
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
        end)

        describe("StructuralEquals (Strict + OfStructure)", function()
            it("should reject arrays with additional contents", function()
                local Checker = Base:StructuralEquals({TypeGuard.Number(), TypeGuard.Number()})
                expect(Checker:Check({1, 2})).to.equal(true)
                expect(Checker:Check({1, 2, 3})).to.equal(false)
            end)
        end)
    end)

    describe("Nil", function()
        describe("Init", function()
            it("should accept nil", function()
                expect(TypeGuard.Nil():Check(nil)).to.equal(true)
            end)

            it("should reject non-nil", function()
                expect(TypeGuard.Nil():Check(1)).to.equal(false)
                expect(TypeGuard.Nil():Check(function() end)).to.equal(false)
                expect(TypeGuard.Nil():Check({})).to.equal(false)
                expect(TypeGuard.Nil():Check(false)).to.equal(false)
            end)
        end)
    end)

    describe("Enum", function()
        describe("Init", function()
            it("should throw given non-EnumItem, non-Enum values", function()
                expect(function()
                    TypeGuard.Enum(1)
                end).to.throw()

                expect(function()
                    TypeGuard.Enum(function() end)
                end).to.throw()

                expect(function()
                    TypeGuard.Enum({})
                end).to.throw()
            end)

            it("should not throw given EnumItem or Enum values", function()
                expect(function()
                    TypeGuard.Enum(Enum.AccessoryType)
                end).never.to.throw()

                expect(function()
                    TypeGuard.Enum(Enum.AccessoryType.Shirt)
                end).never.to.throw()
            end)
        end)

        describe("IsA", function()
            it("should accept an Enum item if the respective EnumItem is a sub-item", function()
                expect(TypeGuard.Enum(Enum.AccessoryType):Check(Enum.AccessoryType.Shirt)).to.equal(true)
            end)

            it("should reject EnumItems which are not part of the Enum class", function()
                expect(TypeGuard.Enum(Enum.AccessoryType):Check(Enum.AlphaMode.Overlay)).to.equal(false)
            end)

            it("should accept EnumItems which are equal", function()
                expect(TypeGuard.Enum(Enum.AccessoryType.Face):Check(Enum.AccessoryType.Face)).to.equal(true)
            end)
        end)
    end)

    describe("Thread", function()
        local Base = TypeGuard.Thread()

        describe("Init", function()
            it("should reject non-thread values", function()
                expect(Base:Check(1)).to.equal(false)
                expect(Base:Check(function() end)).to.equal(false)
                expect(Base:Check({})).to.equal(false)
            end)

            it("should accept thread values", function()
                expect(Base:Check(coroutine.create(function() end))).to.equal(true)
            end)
        end)

        describe("HasStatus", function()
            it("should accept running threads given 'running'", function()
                local Thread = coroutine.running()

                expect(Base:HasStatus("suspended"):Check(Thread)).to.equal(false)
                expect(Base:HasStatus("running"):Check(Thread)).to.equal(true)
                expect(Base:HasStatus("normal"):Check(Thread)).to.equal(false)
                expect(Base:HasStatus("dead"):Check(Thread)).to.equal(false)
            end)

            it("should accept suspended threads given 'suspended'", function()
                local Thread = task.spawn(function()
                    task.wait(1)
                end)

                expect(Base:HasStatus("suspended"):Check(Thread)).to.equal(true)
                expect(Base:HasStatus("running"):Check(Thread)).to.equal(false)
                expect(Base:HasStatus("normal"):Check(Thread)).to.equal(false)
                expect(Base:HasStatus("dead"):Check(Thread)).to.equal(false)
            end)

            it("should accept threads given 'dead'", function()
                local Thread = task.spawn(function() end)

                expect(Base:HasStatus("suspended"):Check(Thread)).to.equal(false)
                expect(Base:HasStatus("running"):Check(Thread)).to.equal(false)
                expect(Base:HasStatus("normal"):Check(Thread)).to.equal(false)
                expect(Base:HasStatus("dead"):Check(Thread)).to.equal(true)
            end)

            it("should accept threads given 'normal'", function()
                local DidRun = false
                local TestCoroutine = coroutine.create(function(Callback)
                    Callback()
                end)

                task.spawn(function()
                    local Thread = coroutine.running()

                    task.spawn(TestCoroutine, function()
                        expect(Base:HasStatus("suspended"):Check(Thread)).to.equal(false)
                        expect(Base:HasStatus("running"):Check(Thread)).to.equal(false)
                        expect(Base:HasStatus("normal"):Check(Thread)).to.equal(true)
                        expect(Base:HasStatus("dead"):Check(Thread)).to.equal(false)
                        DidRun = true
                    end)
                end)

                expect(DidRun).to.equal(true)
            end)
        end)
    end)

    describe("Object", function()
        local Base = TypeGuard.Object()

        describe("Init", function()
            it("should reject non-object values", function()
                expect(Base:Check(1)).to.equal(false)
                expect(Base:Check(function() end)).to.equal(false)
                expect(Base:Check({1})).to.equal(false)
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

        describe("StructuralEquals (OfStructure + Strict)", function()
            it("should accept an object with the given structure", function()
                expect(Base:StructuralEquals({
                    Test = TypeGuard.Number(),
                    Another = TypeGuard.Boolean()
                }):Check({Test = 123, Another = true})).to.equal(true)
            end)

            it("should reject an object with a different structure", function()
                expect(Base:StructuralEquals({
                    Test = TypeGuard.Number(),
                    Another = TypeGuard.Boolean()
                }):Check({Test = 123, Another = "true"})).to.equal(false)
            end)

            it("should reject additional fields when not in strict mode", function()
                expect(Base:StructuralEquals({
                    Test = TypeGuard.Number(),
                    Another = TypeGuard.Boolean()
                }):Check({Test = 123, Another = true, Test2 = "123"})).to.equal(false)
            end)

            it("should recurse given sub object TypeCheckers but not enforce strict recursively", function()
                expect(Base:StructuralEquals({
                    Test = TypeGuard.Object({
                        Test = TypeGuard.Number(),
                        Another = TypeGuard.Boolean()
                    })
                }):Check({Test = {Test = 123, Another = true, Final = {}}})).to.equal(true)
            end)
        end)
    end)
end