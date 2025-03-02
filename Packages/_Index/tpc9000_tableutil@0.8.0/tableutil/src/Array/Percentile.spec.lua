return function()
    local Percentile = require(script.Parent.Parent).Array.Percentile

    describe("Array/Percentile", function()
        it("should return nil for no elements", function()
            expect(Percentile({}, 0)).to.equal(nil)
        end)

        it("should return the first element for a single element", function()
            expect(Percentile({1}, 1)).to.equal(1)
        end)

        it("should return the middle element for 50th percentile", function()
            expect(Percentile({1, 2, 3, 4, 5}, 0.5)).to.equal(3)
        end)

        it("should return the last element for 100th percentile", function()
            expect(Percentile({1, 2, 3, 4, 5}, 1)).to.equal(5)
        end)
    end)
end