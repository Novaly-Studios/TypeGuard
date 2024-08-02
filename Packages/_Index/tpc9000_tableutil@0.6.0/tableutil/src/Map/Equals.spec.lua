return function()
    local Equals = require(script.Parent.Equals)

    describe("Map/Equals", function()
        it("it should return true for two empty tables", function()
            expect(Equals({}, {})).to.equal(true)
        end)

        it("should return false for one item in X and none in Y", function()
            expect(Equals({a = 1}, {})).to.equal(false)
        end)

        it("should return false for one item in Y and none in X", function()
            expect(Equals({}, {a = 1})).to.equal(false)
        end)

        it("should return false for one item in X and one item in Y with different keys", function()
            expect(Equals({a = 1}, {b = 1})).to.equal(false)
        end)

        it("should return false for one item in X and one item in Y with different values", function()
            expect(Equals({a = 1}, {a = 2})).to.equal(false)
        end)

        it("should return true for one item in X and one item in Y with the same key and value", function()
            expect(Equals({a = 1}, {a = 1})).to.equal(true)
        end)

        it("should return true for two items in X and two items in Y with the same keys and values", function()
            expect(Equals({a = 1, b = 2}, {a = 1, b = 2})).to.equal(true)
        end)
    end)
end