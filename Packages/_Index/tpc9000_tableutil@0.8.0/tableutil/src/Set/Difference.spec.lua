return function()
    local Set = require(script.Parent.Parent).Set
        local Difference = Set.Difference
        local FromValues = Set.FromValues

    describe("Set/Difference", function()
        it("should return a blank set from two blank set inputs", function()
            local Result = Difference(FromValues({}), FromValues({}))
            expect(next(Result)).never.to.be.ok()
        end)

        it("should return en empty set from two equal set inputs", function()
            local Test = FromValues({1, 2, 3})
            local Result = Difference(Test, Test)
            expect(Result).to.be.a("table")
            expect(next(Result)).never.to.be.ok()
        end)

        it("should return the left side set if the right side is empty and the left side is frozen", function()
            local X = FromValues({1, 2, 3})
            local Y = FromValues({})

            local Result = Difference(X, Y)
            expect(Result).to.equal(X)
            expect(Result).to.never.equal(Y)
        end)

        it("should return the left side set if it is empty and frozen", function()
            local X = FromValues({})
            local Y = FromValues({1, 2, 3})

            local Result = Difference(X, Y)
            expect(Result).to.equal(X)
            expect(Result).to.never.equal(Y)
        end)

        it("should remove the latter from the former with one item", function()
            local Result = Difference(FromValues({1}), FromValues({1}))
            expect(next(Result)).never.to.be.ok()
        end)

        it("should remove the latter from the former with multiple items", function()
            local Result = Difference(FromValues({1, 4, 8}), FromValues({4, 8, 1}))
            expect(next(Result)).never.to.be.ok()
        end)

        it("should remove the latter from the former with multiple items and leave non-negated present", function()
            local Result = Difference(FromValues({1, 4, 8, 2}), FromValues({4, 8, 1}))
            expect(Result[2]).to.be.ok()
        end)
    end)
end