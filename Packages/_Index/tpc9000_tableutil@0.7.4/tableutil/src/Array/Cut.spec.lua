return function()
    local Cut = require(script.Parent.Parent).Array.Cut

    describe("Array/Cut", function()
        it("should return the first element given range 1, 1", function()
            local Result = Cut({1234}, 1, 1)
            expect(Result[1]).to.equal(1234)
        end)

        it("should return the middle two elements of a 4-item array given range 2, 3", function()
            local Result = Cut({1, 2, 3, 4}, 2, 3)
            expect(Result[1]).to.equal(2)
            expect(Result[2]).to.equal(3)
            expect(Result[3]).never.to.be.ok()
        end)

        it("should return the original array if the range is equivalent to the array's length", function()
            local Test = {1, 2, 3, 4}
            local Result = Cut(Test, 1, 4)

            expect(Result).to.equal(Test)
        end)
    end)
end