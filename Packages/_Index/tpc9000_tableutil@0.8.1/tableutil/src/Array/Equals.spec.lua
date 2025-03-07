return function()
    local Equals = require(script.Parent.Parent).Array.Equals

    describe("Array/Equals", function()
        it("should return true for two empty tables", function()
            expect(Equals({}, {})).to.equal(true)
        end)

        it("should return false for one item in X and none in Y", function()
            expect(Equals({"Test"}, {})).to.equal(false)
        end)

        it("should return false for one item in Y and none in X", function()
            expect(Equals({}, {"Test"})).to.equal(false)
        end)

        it("should return false for arrays of differnet sizes", function()
            expect(Equals({1, 2, 3}, {1, 2})).to.equal(false)
            expect(Equals({1, 2}, {1, 2, 3})).to.equal(false)
        end)

        it("should return true for two equal arrays", function()
            expect(Equals({1, 2, 3}, {1, 2, 3})).to.equal(true)
            expect(Equals({1}, {1})).to.equal(true)
        end)
    end)
end