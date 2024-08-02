return function()
    local FromValues = require(script.Parent.FromValues)
    local Equals = require(script.Parent.Equals)

    describe("Set/Equals", function()
        it("should return true for two empty sets", function()
            expect(Equals(FromValues({}), FromValues({}))).to.equal(true)
        end)

        it("should return false for two sets with different values", function()
            expect(Equals(FromValues({1, 2, 3}), FromValues({4, 5, 6}))).to.equal(false)
        end)

        it("should return true for two sets with the same values", function()
            expect(Equals(FromValues({1, 2, 3}), FromValues({1, 2, 3}))).to.equal(true)
            expect(Equals(FromValues({1, 2, 3}), FromValues({3, 2, 1}))).to.equal(true)
        end)

        it("should return false for an intersection which is not equal to A or B", function()
            expect(Equals(FromValues({1, 2, 3}), FromValues({2, 3, 4}))).to.equal(false)
            expect(Equals(FromValues({1, 2, 3}), FromValues({1, 2, 4}))).to.equal(false)
        end)
    end)
end