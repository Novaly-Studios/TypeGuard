return function()
    local Merge = require(script.Parent.Merge)

    describe("Map/Merge", function()
        it("should return the left table if the right is blank", function()
            local Left = {X = 1}
            local Right = {}

            expect(Merge(Left, Right)).to.equal(Left)
        end)

        it("should return the right table if the left is blank", function()
            local Left = {}
            local Right = {X = 1}

            expect(Merge(Left, Right)).to.equal(Right)
        end)

        it("should return a flat merge of two tables", function()
            local Left = {X = 1, Y = 2}
            local Right = {Z = 3, W = 4}
            local Result = Merge(Left, Right)

            expect(Result).to.be.ok()
            expect(Result).to.never.equal(Left)
            expect(Result).to.never.equal(Right)
            expect(Result.X).to.equal(1)
            expect(Result.Y).to.equal(2)
            expect(Result.Z).to.equal(3)
            expect(Result.W).to.equal(4)
        end)

        it("should overwrite values in the left table with values from the right", function()
            local Left = {X = 1, Y = 2}
            local Right = {Y = 3, Z = 4}
            local Result = Merge(Left, Right)

            expect(Result).to.be.ok()
            expect(Result).to.never.equal(Left)
            expect(Result).to.never.equal(Right)
            expect(Result.X).to.equal(1)
            expect(Result.Y).to.equal(3)
            expect(Result.Z).to.equal(4)
        end)
    end)
end