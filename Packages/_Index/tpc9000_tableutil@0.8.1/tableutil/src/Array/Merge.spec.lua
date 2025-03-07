return function()
    local Merge = require(script.Parent.Parent).Array.Merge

    describe("Array/Merge", function()
        it("should return a new array when both are non-empty", function()
            local X = {1, 2, 3}
            local Y = {4, 5, 6}

            local Result = Merge(X, Y)
            expect(Result).to.be.a("table")
            expect(Result).to.never.be.equal(X)
            expect(Result).to.never.be.equal(Y)
        end)

        it("should return a new array with the contents of both arrays", function()
            local X = {1, 2, 3}
            local Y = {4, 5, 6}

            local Result = Merge(X, Y)
            expect(Result).to.be.a("table")
            expect(Result[1]).to.equal(1)
            expect(Result[2]).to.equal(2)
            expect(Result[3]).to.equal(3)
            expect(Result[4]).to.equal(4)
            expect(Result[5]).to.equal(5)
            expect(Result[6]).to.equal(6)
        end)

        it("should return the opposite side array when frozen and when the other is empty", function()
            local X = table.freeze({1, 2, 3})
            local Y = table.freeze({})

            local Result = Merge(X, Y)
            expect(Result).to.be.a("table")
            expect(Result).to.equal(X)
            expect(Result).to.never.equal(Y)

            Result = Merge(Y, X)
            expect(Result).to.be.a("table")
            expect(Result).to.equal(X)
            expect(Result).to.never.equal(Y)
        end)

        it("should return a copy of the original array when not frozen and one side empty", function()
            local X = {1, 2, 3}
            local Y = {}

            local Result = Merge(X, Y)
            expect(Result).to.be.a("table")
            expect(Result).never.to.equal(X)
            expect(Result).never.to.equal(Y)
            expect(Result[1]).to.equal(1)
            expect(Result[2]).to.equal(2)
            expect(Result[3]).to.equal(3)
        end)

        it("should correctly merge two of the same array", function()
            local X = table.freeze({1, 2, 3})
            local Y = X

            local Result = Merge(X, Y)
            expect(Result).to.be.a("table")
            expect(Result[1]).to.equal(1)
            expect(Result[2]).to.equal(2)
            expect(Result[3]).to.equal(3)
            expect(Result[4]).to.equal(1)
            expect(Result[5]).to.equal(2)
            expect(Result[6]).to.equal(3)
        end)
    end)
end