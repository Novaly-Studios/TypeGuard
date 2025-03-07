return function()
    local Sum = require(script.Parent.Parent).Array.Sum

    describe("Array/Sum", function()
        it("should return the sum of a single element for From & To being equal", function()
            expect(Sum({1}, 1, 1)).to.equal(1)
        end)

        it("should return the sum of a subset of multiple elements", function()
            expect(Sum({1, 2, 3, 4}, 1, 3)).to.equal(6)
        end)

        it("should return the sum of a subset of multiple elements where From is greater than To", function()
            expect(Sum({1, 2, 3, 4}, 3, 1)).to.equal(6)
        end)
    end)
end