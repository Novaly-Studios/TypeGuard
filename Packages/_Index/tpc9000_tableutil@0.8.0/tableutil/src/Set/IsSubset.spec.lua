return function()
    local Set = require(script.Parent.Parent).Set
        local FromValues = Set.FromValues
        local IsSubset = Set.IsSubset

    describe("Set/IsSubset", function()
        it("should return true for two empty sets", function()
            expect(IsSubset(FromValues({}), FromValues({}))).to.equal(true)
        end)

        it("should return false for a set and an empty set", function()
            expect(IsSubset(FromValues({1, 2, 3}), FromValues({}))).to.equal(false)
        end)

        it("should return true for an empty set and a set", function()
            expect(IsSubset(FromValues({}), FromValues({1, 2, 3}))).to.equal(true)
        end)

        it("should return true for a set and a subset", function()
            expect(IsSubset(FromValues({1, 2}), FromValues({1, 2, 3}))).to.equal(true)
        end)

        it("should return false for a set and a non-subset", function()
            expect(IsSubset(FromValues({1, 2, 3}), FromValues({1, 2, 4}))).to.equal(false)
        end)

        it("should return false for a set and a superset", function()
            expect(IsSubset(FromValues({1, 2, 3, 4}), FromValues({1, 2, 3}))).to.equal(false)
        end)

        it("should return true for a set and itself", function()
            expect(IsSubset(FromValues({1, 2, 3}), FromValues({1, 2, 3}))).to.equal(true)
        end)
    end)
end