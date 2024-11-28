return function()
    local MutableMerge = require(script.Parent.Parent).Map.MutableMerge

    describe("Map/MutableMerge", function()
        it("should not modify a blank table given a blank table to merge in", function()
            local Result = {}
            MutableMerge(Result, {})
            expect(next(Result)).never.to.be.ok()
        end)

        it("should flat modify a table given a single item table to merge in", function()
            local Result = {}
            MutableMerge(Result, {A = 1})
            expect(Result.A).to.equal(1)
        end)

        it("should flat modify a table given a multiple item table to merge in", function()
            local Result = {}
            MutableMerge(Result, {A = 1, B = 2, C = 3})
            expect(Result.A).to.equal(1)
            expect(Result.B).to.equal(2)
            expect(Result.C).to.equal(3)
        end)

        it("should overwrite former tables", function()
            local Result = {A = 1, B = 2}
            MutableMerge(Result, {B = 4})
            expect(Result.A).to.equal(1)
            expect(Result.B).to.equal(4)
        end)

        it("should merge in false values", function()
            local Result = {A = 1, B = 2}
            MutableMerge(Result, {B = false})
            expect(Result.A).to.equal(1)
            expect(Result.B).to.equal(false)
        end)

        it("should preserve a metatable on the left-side table with a non-metatable on the right-side table", function()
            local MT = {__len = function() end}
            local Left = setmetatable({A = 1, B = 2}, MT)
            local Right = {C = 3, D = 4}
            MutableMerge(Left, Right)
            expect(getmetatable(Left)).to.equal(MT)
        end)

        it("should overwrite a left-side metatable with a right-side metatable", function()
            local MT = {__len = function() end}
            local MT2 = {__len = function() end}
            local Left = setmetatable({A = 1, B = 2}, MT)
            local Right = setmetatable({C = 3, D = 4}, MT2)
            MutableMerge(Left, Right)
            expect(getmetatable(Left)).to.equal(MT2)
        end)
    end)
end