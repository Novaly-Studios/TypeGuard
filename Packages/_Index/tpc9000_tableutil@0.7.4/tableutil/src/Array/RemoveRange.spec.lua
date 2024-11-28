return function()
    local RemoveRange = require(script.Parent.Parent).Array.RemoveRange

    describe("Array/RemoveRange", function()
        it("should return the same array given the full range", function()
            local Sample = {1, 2, 3}
            local Result = RemoveRange(Sample, 1, 3)
            expect(Result).to.equal(Sample)
        end)

        it("should remove the given range of values in a new array", function()
            local Sample = {1, 2, 3, 4, 5, 6, 7, 8, 9, 10}
            local Result = RemoveRange(Sample, 3, 6)
            expect(Result).to.be.a("table")
            expect(Result).never.to.equal(Sample)
            expect(Result[1]).to.equal(1)
            expect(Result[2]).to.equal(2)
            expect(Result[3]).to.equal(7)
            expect(Result[4]).to.equal(8)
            expect(Result[5]).to.equal(9)
            expect(Result[6]).to.equal(10)
        end)
    end)
end