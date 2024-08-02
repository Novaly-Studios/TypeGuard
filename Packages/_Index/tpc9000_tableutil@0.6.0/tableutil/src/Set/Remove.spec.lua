local Set = require(script.Parent)
local Remove = require(script.Parent:FindFirstChild("Remove"))

return function()
    describe("Set/Remove", function()
        it("should return the same set given a nil value", function()
            local Sample1 = Set({})
            expect(Remove(Sample1, nil)).to.equal(Sample1)

            local Sample2 = Set({1, 2, 3})
            expect(Remove(Sample2, nil)).to.equal(Sample2)
        end)

        it("should return the same empty set given a value and an empty set", function()
            local Sample = Set({})
            expect(Remove(Sample, 1)).to.equal(Sample)
        end)

        it("should return the same set given a value not in the set", function()
            local Sample = Set({1, 2, 3})
            expect(Remove(Sample, 4)).to.equal(Sample)
        end)

        it("should return a new set without the given value", function()
            local Sample = Set({1, 2, 3})
            local Result = Remove(Sample, 2)
            expect(Result).never.to.equal(Sample)
            expect(Result[1]).to.equal(true)
            expect(Result[2]).never.to.be.ok()
            expect(Result[3]).to.equal(true)
        end)
    end)
end