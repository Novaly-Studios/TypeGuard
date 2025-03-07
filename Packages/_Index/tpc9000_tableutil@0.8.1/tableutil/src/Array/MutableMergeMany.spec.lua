return function()
    local MutableMergeMany = require(script.Parent.Parent).Array.MutableMergeMany

    describe("Array/MutableMergeMany", function()
        it("should not add anything to the array when the right-hand table is empty", function()
            local Left = {1, 2, 3}
            local Right = {}
            MutableMergeMany(Left, Right)

            expect(Left[1]).to.equal(1)
            expect(Left[2]).to.equal(2)
            expect(Left[3]).to.equal(3)
            expect(Left[4]).to.equal(nil)
        end)

        it("should merge one right-hand array into the left-hand array", function()
            local Left = {1, 2, 3}
            local Right = {4, 5, 6}
            MutableMergeMany(Left, Right)

            expect(Left[1]).to.equal(1)
            expect(Left[2]).to.equal(2)
            expect(Left[3]).to.equal(3)
            expect(Left[4]).to.equal(4)
            expect(Left[5]).to.equal(5)
            expect(Left[6]).to.equal(6)
            expect(Left[7]).to.equal(nil)
        end)

        it("should merge multiple right-hand arrays into the left-hand array", function()
            local Left = {1, 2, 3}
            local Right1 = {4, 5, 6}
            local Right2 = {7, 8, 9}
            MutableMergeMany(Left, Right1, Right2)

            expect(Left[1]).to.equal(1)
            expect(Left[2]).to.equal(2)
            expect(Left[3]).to.equal(3)
            expect(Left[4]).to.equal(4)
            expect(Left[5]).to.equal(5)
            expect(Left[6]).to.equal(6)
            expect(Left[7]).to.equal(7)
            expect(Left[8]).to.equal(8)
            expect(Left[9]).to.equal(9)
            expect(Left[10]).to.equal(nil)
        end)
    end)
end