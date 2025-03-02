return function()
    local Set = require(script.Parent.Parent).Set
        local FromValues = Set.FromValues
        local ToArray = Set.ToArray

    describe("Set/ToArray", function()
        it("should return a blank array from a blank set", function()
            local Result = ToArray(FromValues({}))
            expect(Result).to.be.ok()
            expect(#Result).to.equal(0)
        end)

        it("should return an array with the same items as the set", function()
            local Result = ToArray(FromValues({1, 2, 3}))
            expect(Result).to.be.ok()
            expect(#Result).to.equal(3)
            expect(Result[1]).to.equal(1)
            expect(Result[2]).to.equal(2)
            expect(Result[3]).to.equal(3)
        end)
    end)
end