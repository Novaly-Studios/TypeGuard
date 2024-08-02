return function()
    local ToArray = require(script.Parent.ToArray)
    local Set = require(script.Parent)

    describe("Set/ToArray", function()
        it("should return a blank array from a blank set", function()
            local Result = ToArray(Set({}))
            expect(Result).to.be.ok()
            expect(#Result).to.equal(0)
        end)

        it("should return an array with the same items as the set", function()
            local Result = ToArray(Set({1, 2, 3}))
            expect(Result).to.be.ok()
            expect(#Result).to.equal(3)
            expect(Result[1]).to.equal(1)
            expect(Result[2]).to.equal(2)
            expect(Result[3]).to.equal(3)
        end)
    end)
end