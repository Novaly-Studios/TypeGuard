return function()
    local Count = require(script.Parent.Parent).Map.Count

    describe("Map/Count", function()
        it("it should return 0 for an empty table", function()
            expect(Count({})).to.equal(0)
        end)

        it("should return 1 for a single element table", function()
            expect(Count({A = 1})).to.equal(1)
        end)

        it("should return 2 for a 2 elements table", function()
            expect(Count({A = 1, B = 2})).to.equal(2)
        end)

        it("should return 3 for a 3 elements table", function()
            expect(Count({A = 1, B = 2, C = 3})).to.equal(3)
        end)
    end)
end