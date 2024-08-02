return function()
    local Set = require(script.Parent)
    local IsSubset = require(script.Parent.IsSubset)

    describe("Set/IsSubset", function()
        it("should return true for two empty sets", function()
            expect(IsSubset(Set({}), Set({}))).to.equal(true)
        end)

        it("should return false for a set and an empty set", function()
            expect(IsSubset(Set({1, 2, 3}), Set({}))).to.equal(false)
        end)

        it("should return true for an empty set and a set", function()
            expect(IsSubset(Set({}), Set({1, 2, 3}))).to.equal(true)
        end)

        it("should return true for a set and a subset", function()
            expect(IsSubset(Set({1, 2}), Set({1, 2, 3}))).to.equal(true)
        end)

        it("should return false for a set and a non-subset", function()
            expect(IsSubset(Set({1, 2, 3}), Set({1, 2, 4}))).to.equal(false)
        end)

        it("should return false for a set and a superset", function()
            expect(IsSubset(Set({1, 2, 3, 4}), Set({1, 2, 3}))).to.equal(false)
        end)

        it("should return true for a set and itself", function()
            expect(IsSubset(Set({1, 2, 3}), Set({1, 2, 3}))).to.equal(true)
        end)
    end)
end