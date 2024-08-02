return function()
    local Set = require(script.Parent)
    local IsProperSubset = require(script.Parent.IsProperSubset)

    describe("Set/IsProperSubset", function()
        it("should return false for two empty sets", function()
            expect(IsProperSubset(Set({}), Set({}))).to.equal(false)
        end)

        it("should return false for a set and an empty set", function()
            expect(IsProperSubset(Set({1, 2, 3}), Set({}))).to.equal(false)
        end)

        it("should return true for an empty set and a set", function()
            expect(IsProperSubset(Set({}), Set({1, 2, 3}))).to.equal(true)
        end)

        it("should return true for a set and a superset", function()
            expect(IsProperSubset(Set({1, 2}), Set({1, 2, 3}))).to.equal(true)
        end)

        it("should return false for a set and a non-superset", function()
            expect(IsProperSubset(Set({1, 2, 3}), Set({1, 2, 4}))).to.equal(false)
        end)

        it("should return false for a set and a subset", function()
            expect(IsProperSubset(Set({1, 2, 3, 4}), Set({1, 2, 3}))).to.equal(false)
        end)

        it("should return false for a set and itself", function()
            expect(IsProperSubset(Set({1, 2, 3}), Set({1, 2, 3}))).to.equal(false)
        end)
    end)
end