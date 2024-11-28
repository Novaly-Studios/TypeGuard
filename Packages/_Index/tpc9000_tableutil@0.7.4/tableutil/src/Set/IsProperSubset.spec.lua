return function()
    local Set = require(script.Parent.Parent).Set
        local IsProperSubset = Set.IsProperSubset
        local FromValues = Set.FromValues

    describe("Set/IsProperSubset", function()
        it("should return false for two empty sets", function()
            expect(IsProperSubset(FromValues({}), FromValues({}))).to.equal(false)
        end)

        it("should return false for a set and an empty set", function()
            expect(IsProperSubset(FromValues({1, 2, 3}), FromValues({}))).to.equal(false)
        end)

        it("should return true for an empty set and a set", function()
            expect(IsProperSubset(FromValues({}), FromValues({1, 2, 3}))).to.equal(true)
        end)

        it("should return true for a set and a superset", function()
            expect(IsProperSubset(FromValues({1, 2}), FromValues({1, 2, 3}))).to.equal(true)
        end)

        it("should return false for a set and a non-superset", function()
            expect(IsProperSubset(FromValues({1, 2, 3}), FromValues({1, 2, 4}))).to.equal(false)
        end)

        it("should return false for a set and a subset", function()
            expect(IsProperSubset(FromValues({1, 2, 3, 4}), FromValues({1, 2, 3}))).to.equal(false)
        end)

        it("should return false for a set and itself", function()
            expect(IsProperSubset(FromValues({1, 2, 3}), FromValues({1, 2, 3}))).to.equal(false)
        end)
    end)
end