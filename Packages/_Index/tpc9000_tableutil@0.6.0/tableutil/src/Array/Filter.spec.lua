return function()
    local Filter = require(script.Parent.Filter)

    describe("Array/Filter", function()
        it("should return a blank table for no data", function()
            local Results = Filter({}, function()
                return true
            end)

            expect(next(Results)).never.to.be.ok()
        end)

        it("should return all items in order for true condition", function()
            local Results = Filter({3, 2, 1}, function()
                return true
            end)

            expect(Results[1]).to.equal(3)
            expect(Results[2]).to.equal(2)
            expect(Results[3]).to.equal(1)
        end)

        it("should return no items for false condition", function()
            local Results = Filter({3, 2, 1}, function()
                return false
            end)

            expect(next(Results)).never.to.be.ok()
        end)

        it("should filter all items larger than some value in order", function()
            local Results = Filter({8, 4, 2, 1}, function(Value)
                return Value >= 4
            end)

            expect(Results[1]).to.equal(8)
            expect(Results[2]).to.equal(4)
            expect(Results[3]).never.to.be.ok()
        end)

        it("should pass the index in order", function()
            Filter({1, 2, 3, 4}, function(Value, Index)
                expect(Index).to.equal(Value)
                return true
            end)
        end)
    end)
end