return function()
    local MutableMergeMany = require(script.Parent.MutableMergeMany)

    describe("Map/MutableMergeMany", function()
        it("should not modify a blank table given a blank table to merge in", function()
            local Result = {}
            MutableMergeMany(Result, {})
            expect(next(Result)).never.to.be.ok()
        end)

        it("should flat modify a table given a single item table to merge in", function()
            local Result = {}
            MutableMergeMany(Result, {A = 1})
            expect(Result.A).to.equal(1)
        end)

        it("should flat modify a table given a multiple item table to merge in", function()
            local Result = {}
            MutableMergeMany(Result, {A = 1, B = 2, C = 3})
            expect(Result.A).to.equal(1)
            expect(Result.B).to.equal(2)
            expect(Result.C).to.equal(3)
        end)

        it("should overwrite former tables", function()
            local Result = {A = 1, B = 2}
            MutableMergeMany(Result, {B = 3}, {B = 4})
            expect(Result.A).to.equal(1)
            expect(Result.B).to.equal(4)
        end)

        it("should merge in false values", function()
            local Result = {A = 1, B = 2}
            MutableMergeMany(Result, {B = false})
            expect(Result.A).to.equal(1)
            expect(Result.B).to.equal(false)
        end)
    end)
end