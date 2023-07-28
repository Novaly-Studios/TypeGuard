local function anyfn(...) return ({} :: any) end
it = it or anyfn
expect = expect or anyfn
describe = describe or anyfn

return function()
    local TypeGuard = require(script.Parent.Parent)
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
    
    describe("InitialConstraint", function()
        it("should check for str1 or str2 or etc.", function()
            local Test = TypeGuard.String("X", "Y")
            expect(Test:Check("X")).to.equal(true)
            expect(Test:Check("Y")).to.equal(true)
            expect(Test:Check("Z")).to.equal(false)
        end)
    end)

    describe("MinLength", function()
        it("should reject strings shorter than the specified length", function()
            expect(Base:MinLength(5):Check("Test")).to.equal(false)
            expect(Base:MinLength(function()
                return 5
            end):Check("Test")).to.equal(false)
        end)

        it("should accept strings longer than the specified length", function()
            expect(Base:MinLength(5):Check("Test123")).to.equal(true)
            expect(Base:MinLength(function()
                return 5
            end):Check("Test123")).to.equal(true)
        end)

        it("should accept strings equal to the specified length", function()
            expect(Base:MinLength(5):Check("12345")).to.equal(true)
            expect(Base:MinLength(function()
                return 5
            end):Check("12345")).to.equal(true)
        end)
    end)

    describe("MaxLength", function()
        it("should reject strings longer than the specified length", function()
            expect(Base:MaxLength(5):Check("Test123")).to.equal(false)
            expect(Base:MaxLength(function()
                return 5
            end):Check("Test123")).to.equal(false)
        end)

        it("should accept strings shorter than the specified length", function()
            expect(Base:MaxLength(5):Check("Test")).to.equal(true)
            expect(Base:MaxLength(function()
                return 5
            end):Check("Test")).to.equal(true)
        end)

        it("should accept strings equal to the specified length", function()
            expect(Base:MaxLength(5):Check("12345")).to.equal(true)
            expect(Base:MaxLength(function()
                return 5
            end):Check("12345")).to.equal(true)
        end)
    end)

    describe("Pattern", function()
        it("should accept strings matching the specified pattern", function()
            expect(Base:Pattern("[0-9]+"):Check("34789275")).to.equal(true)
            expect(Base:Pattern(function()
                return "[0-9]+"
            end):Check("34789275")).to.equal(true)
        end)

        it("should reject strings not matching the specified pattern", function()
            expect(Base:Pattern("[0-9]+"):Check("123h4")).to.equal(false)
            expect(Base:Pattern(function()
                return "[0-9]+"
            end):Check("123h4")).to.equal(false)
        end)
    end)

    describe("Contains", function()
        it("should accept strings containing the specified substring", function()
            expect(Base:Contains("Test"):Check("------Test123")).to.equal(true)
            expect(Base:Contains(function()
                return "Test"
            end):Check("------Test123")).to.equal(true)
        end)

        it("should reject strings not containing the specified substring", function()
            expect(Base:Contains("Test"):Check("asdfghjkl")).to.equal(false)
            expect(Base:Contains(function()
                return "Test"
            end):Check("asdfghjkl")).to.equal(false)
        end)
    end)
end