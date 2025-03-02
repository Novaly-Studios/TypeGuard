return function()
    local IsPureArray = require(script.Parent.IsPureArray)

    describe("Shared/IsPureArray", function()
        it("should return false for an empty array", function()
            expect(IsPureArray({})).to.equal(false)
        end)

        it("should return true for a one-item array", function()
            expect(IsPureArray({1})).to.equal(true)
        end)

        it("should return true for a two-item array", function()
            expect(IsPureArray({1, 2})).to.equal(true)
        end)

        it("should return false for a two-item array with a string key", function()
            expect(IsPureArray({1, 2, X = 3})).to.equal(false)
        end)
    end)
end