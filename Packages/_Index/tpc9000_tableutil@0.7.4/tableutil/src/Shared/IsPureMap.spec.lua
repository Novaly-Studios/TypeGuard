return function()
    local IsPureMap = require(script.Parent.IsPureMap)

    describe("Shared/IsPureMap", function()
        it("should return false a blank table", function()
            expect(IsPureMap({})).to.equal(false)
        end)

        it("should return true for a table with a single item", function()
            expect(IsPureMap({A = 1})).to.equal(true)
        end)

        it("should return true for a table with multiple items", function()
            expect(IsPureMap({A = 1, B = 2, C = 3})).to.equal(true)
        end)

        it("should return false for a mixed table", function()
            expect(IsPureMap({1, 2, 3, A = 1, B = 2, C = 3})).to.equal(false)
        end)

        it("should return false for an array", function()
            expect(IsPureMap({1, 2, 3})).to.equal(false)
        end)
    end)
end