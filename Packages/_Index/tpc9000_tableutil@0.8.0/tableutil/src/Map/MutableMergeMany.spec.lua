return function()
    local MutableMergeMany = require(script.Parent.Parent).Map.MutableMergeMany

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

        it("should allow left-hand metatables to be overwriten by right-hand metatables", function()
            local MT1 = {__gt = function() return false end}
            local MT2 = {__gt = function() return false end}
            local MT3 = {__gt = function() return false end}

            local Result = setmetatable({A = 1}, MT1)
            MutableMergeMany(
                Result,
                setmetatable({B = 2}, MT2),
                setmetatable({C = 3}, MT3)
            )

            expect(Result).to.be.ok()
            expect(Result).to.be.a("table")
            expect(getmetatable(Result)).to.equal(MT3)
            expect(Result.A).to.equal(1)
            expect(Result.B).to.equal(2)
            expect(Result.C).to.equal(3)
        end)

        it("should preserve left-side metatables when right-side has no metatable", function()
            local MT1 = {__gt = function() return false end}
            local Result = setmetatable({Value1 = 1}, MT1)
            MutableMergeMany(
                Result,
                {Value2 = 2}
            )
            expect(getmetatable(Result)).to.equal(MT1)
            expect(Result.Value1).to.equal(1)
            expect(Result.Value2).to.equal(2)
        end)

        it("should apply a mapper function to values when enabled", function()
            local Test1 = {X = 1}
            MutableMergeMany(Test1, {X = function(Value)
                return Value + 1
            end})
            expect(Test1.X).to.be.a("function")

            local Test2 = {X = 1}
            MutableMergeMany(Test2, {X = function(Value)
                return Value + 1
            end}, true)
            expect(Test2.X).to.equal(2)

            local Test3 = {X = 1}
            MutableMergeMany(Test3, {X = function(Value)
                return Value + 1
            end}, {X = function(Value)
                return 123
            end}, true)
            expect(Test3.X).to.equal(123)
        end)
    end)
end