return function()
    local IsArray = require(script.Parent.IsArray)

    describe("Array/IsArray", function()
        it("should return false for an empty array", function()
            expect(IsArray({})).to.equal(false)
        end)

        it("should return true for a one-item array", function()
            expect(IsArray({1})).to.equal(true)
        end)

        it("should return true for a two-item array", function()
            expect(IsArray({1, 2})).to.equal(true)
        end)

        it("should return true for a two-item array with a string key", function()
            expect(IsArray({1, 2, X = 3})).to.equal(true)
        end)
    end)
end