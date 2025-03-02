return function()
    local Set = require(script.Parent.Parent).Set
        local SymmetricDifference = Set.SymmetricDifference
        local FromValues = Set.FromValues

    describe("Set/SymmetricDifference", function()
        it("should return a blank set from two blank set inputs", function()
            local Result = SymmetricDifference(FromValues({}), FromValues({}))
            expect(next(Result)).never.to.be.ok()
        end)

        it("should return the opposite set when frozen and when the other is empty", function()
            local X = FromValues({1, 2, 3})
            local Y = FromValues({})

            local Result = SymmetricDifference(X, Y)
            expect(Result).to.equal(X)
            expect(Result).never.to.equal(Y)

            Result = SymmetricDifference(Y, X)
            expect(Result).to.equal(X)
            expect(Result).never.to.equal(Y)
        end)

        it("should return the left items given a left set and a blank right set", function()
            local Result = SymmetricDifference(FromValues({1, 2, 3}), FromValues({}))
            expect(Result[1]).to.be.ok()
            expect(Result[2]).to.be.ok()
            expect(Result[3]).to.be.ok()
        end)

        it("should return the right items given a blank left set and a right set", function()
            local Result = SymmetricDifference(FromValues({}), FromValues({1, 2, 3}))
            expect(Result[1]).to.be.ok()
            expect(Result[2]).to.be.ok()
            expect(Result[3]).to.be.ok()
        end)

        it("should return the SymmetricDifference items without the intersections", function()
            local Result = SymmetricDifference(FromValues({1, 2, 3, 4}), FromValues({3, 4, 5, 6}))
            expect(Result[1]).to.be.ok()
            expect(Result[2]).to.be.ok()
            expect(Result[3]).never.to.be.ok()
            expect(Result[4]).never.to.be.ok()
            expect(Result[5]).to.be.ok()
            expect(Result[6]).to.be.ok()
        end)
    end)
end