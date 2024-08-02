return function()
    local Merge = require(script.Parent.Merge)

    describe("Array/Merge", function()
        it("should return the 1st array when the 2nd is empty", function()
            local X = {1, 2, 3}
            local Y = {}

            local Result = Merge(X, Y)
            expect(Result).to.be.a("table")
            expect(Result).to.be.equal(X)
        end)

        it("should return the 2nd array when the 1st is empty", function()
            local X = {}
            local Y = {1, 2, 3}

            local Result = Merge(X, Y)
            expect(Result).to.be.a("table")
            expect(Result).to.be.equal(Y)
        end)

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

        it("should return the same array when both are the same", function()
            local X = {1, 2, 3}
            local Y = X

            local Result = Merge(X, Y)
            expect(Result).to.be.a("table")
            expect(Result).to.be.equal(X)
            expect(Result).to.be.equal(Y)
        end)
    end)
end