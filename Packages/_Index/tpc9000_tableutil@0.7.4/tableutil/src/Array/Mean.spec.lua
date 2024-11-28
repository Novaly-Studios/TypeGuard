return function()
    local Mean = require(script.Parent.Parent).Array.Mean

    describe("Array/Mean", function()
        it("should return 0 for no elements", function()
            expect(Mean({})).to.equal(0)
        end)

        it("should return the mean of a single element", function()
            expect(Mean({1})).to.equal(1)
        end)

        it("should return the mean of a multiple elements", function()
            expect(Mean({1, 2, 3, 4})).to.equal(2.5)
        end)

        it("should return the mean of a multiple elements with a range", function()
            expect(Mean({1, 2, 3, 4}, 2, 4)).to.equal(3)
        end)
    end)
end