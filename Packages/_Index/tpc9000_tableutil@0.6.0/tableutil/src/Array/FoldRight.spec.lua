return function()
    local FoldRight = require(script.Parent.FoldRight)

    describe("Array/FoldRight", function()
        it("should not call on an empty table", function()
            local Called = false

            FoldRight({}, function()
                Called = true
            end, 1)

            expect(Called).to.equal(false)
        end)

        it("should return an initial value with no operations", function()
            local Result = FoldRight({}, function() end, 1)

            expect(Result).to.equal(1)
        end)

        it("should call in order", function()
            local Indexes = {}

            FoldRight({1, 2, 3, 4}, function(_, _, Index)
                table.insert(Indexes, Index)
            end)

            for Index = 1, 4 do
                expect(Indexes[Index]).to.equal(5 - Index)
            end
        end)

        it("should correctly give the size of the array", function()
            FoldRight({1, 2, 3, 4}, function(_, _, _, Size)
                expect(Size).to.equal(4)
            end)
        end)

        it("should sum up some values with a sum function", function()
            local Result = FoldRight({1, 2, 3, 4}, function(Aggr, Value)
                return Aggr + Value
            end, 0)

            expect(Result).to.equal(10)
        end)
    end)
end