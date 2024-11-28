return function()
    local Set = require(script.Parent.Parent).Set
        local Difference = Set.Difference
        local FromValues = Set.FromValues

    describe("Set/Difference", function()
        it("should return a blank set from two blank set inputs", function()
            local Result = Difference(FromValues({}), FromValues({}))
            expect(next(Result)).never.to.be.ok()
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