-- WIP

return function()
    local Types = require(script.Parent.Types)

    describe("Types.Template", function()
        it("should reject no Name given", function()
            expect(function()
                Types.Template()
            end).to.throw()
        end)

        it("should reject incorrect types for Name", function()
            expect(function()
                Types.Template(1)
            end).to.throw()

            expect(function()
                Types.Template({})
            end).to.throw()

            expect(function()
                Types.Template(true)
            end).to.throw()

            expect(function()
                Types.Template("Test")
            end).never.to.throw()
        end)

        it("should return a constructor function and a TypeChecker class for extension", function()
            local TestCreate, TestClass = Types.Template("Test")
            expect(TestCreate).to.be.a("function")
            expect(TestClass).to.be.a("table")

            expect(TestClass._Copy).to.be.ok()
            expect(TestClass._AddConstraint).to.be.ok()
            expect(TestClass.Optional).to.be.ok()
            expect(TestClass.Or).to.be.ok()
            expect(TestClass.And).to.be.ok()
            expect(TestClass.Alias).to.be.ok()
            expect(TestClass.AddTag).to.be.ok()
            expect(TestClass.WrapCheck).to.be.ok()
            expect(TestClass.WrapAssert).to.be.ok()
            expect(TestClass.Check).to.be.ok()
            expect(TestClass.Assert).to.be.ok()
        end)
    end)

    describe("Types.Params", function()
        it("should reject non-TypeChecker types", function()
            expect(function()
                Types.Params(1)
            end).to.throw()

            expect(function()
                Types.Params({})
            end).to.throw()

            expect(function()
                Types.Params(true)
            end).to.throw()
        end)

        it("should accept TypeChecker types", function()
            expect(function()
                
            end).never.to.throw()
        end)

        it("should check one type", function()
        
        end)

        it("should check multiple types", function()
        
        end)
    end)
end