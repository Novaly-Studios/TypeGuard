return function()
    local MutableMerge = require(script.Parent.MutableMerge)

    describe("Array/MutableMerge", function()
        it("should not add anything to the array when the right-hand table is empty", function()
            local Left = {1, 2, 3}
            local Right = {}
            MutableMerge(Left, Right)

            expect(Left[1]).to.equal(1)
            expect(Left[2]).to.equal(2)
            expect(Left[3]).to.equal(3)
            expect(Left[4]).to.equal(nil)
        end)

        it("should add the elements in the right-hand table to the end of the left-hand table", function()
            local Left = {1, 2, 3}
            local Right = {4, 5, 6}
            MutableMerge(Left, Right)

            expect(Left[1]).to.equal(1)
            expect(Left[2]).to.equal(2)
            expect(Left[3]).to.equal(3)
            expect(Left[4]).to.equal(4)
            expect(Left[5]).to.equal(5)
            expect(Left[6]).to.equal(6)
            expect(Left[7]).to.equal(nil)
        end)
    end)
end