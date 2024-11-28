return function()
    local Reverse = require(script.Parent.Parent).Array.Reverse

    describe("Array/Reverse", function()
        it("should return an empty array if passed an empty array", function()
            local Result = Reverse({})
            expect(next(Result)).never.to.be.ok()
        end)

        it("should return a one-item array from a one-item array", function()
            local Result = Reverse({1})
            expect(Result[1]).to.equal(1)
        end)

        it("should swap two items in a two-item array", function()
            local Result = Reverse({1, 2})
            expect(Result[1]).to.equal(2)
            expect(Result[2]).to.equal(1)
        end)

        it("should swap items in an odd-number-of-items array", function()
            local Result = Reverse({1, 2, 3})
            expect(Result[1]).to.equal(3)
            expect(Result[2]).to.equal(2)
            expect(Result[3]).to.equal(1)
        end)

        it("should reverse 1000 items", function()
            local Result = {}

            for Index = 1, 1000 do
                table.insert(Result, Index)
            end

            Result = Reverse(Result)

            for Index = 1, 1000 do
                expect(Result[Index]).to.equal(1000 - Index + 1)
            end
        end)
    end)
end