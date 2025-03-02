return function()
    local MergeMany = require(script.Parent.Parent).Map.MergeMany

    describe("Map/MergeMany", function()
        it("should return a blank table for no inputs", function()
            local Result = MergeMany()
            expect(next(Result)).never.to.be.ok()
        end)

        it("should return a blank table for one blank table input", function()
            local Result = MergeMany({})
            expect(next(Result)).never.to.be.ok()
        end)

        it("should return a blank table for multiple blank table inputs", function()
            local Result = MergeMany({}, {}, {}, {})
            expect(next(Result)).never.to.be.ok()
        end)

        it("should merge two tables", function()
            local Result = MergeMany({A = 1, B = 2}, {C = 3})
            expect(Result.A).to.equal(1)
            expect(Result.B).to.equal(2)
            expect(Result.C).to.equal(3)
        end)

        it("should overwrite former tables", function()
            local Result = MergeMany({A = 1, B = 2}, {B = 3}, {B = 4})
            expect(Result.A).to.equal(1)
            expect(Result.B).to.equal(4)
        end)

        it("should merge several tables", function()
            local Result = MergeMany({A = 1, B = 2}, {C = 3}, {D = 4})
            expect(Result.A).to.equal(1)
            expect(Result.B).to.equal(2)
            expect(Result.C).to.equal(3)
            expect(Result.D).to.equal(4)
        end)

        it("should allow left-hand metatables to be overwriten by right-hand metatables", function()
            local MT1 = {__gt = function() return false end}
            local MT2 = {__gt = function() return false end}
            local MT3 = {__gt = function() return false end}

            local Result = MergeMany(
                setmetatable({A = 1}, MT1),
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
            local Result = MergeMany(
                setmetatable({Value1 = 1}, MT1),
                {Value2 = 2}
            )
            expect(getmetatable(Result)).to.equal(MT1)
            expect(Result.Value1).to.equal(1)
            expect(Result.Value2).to.equal(2)
        end)

        it("should apply a mapper function to values when enabled", function()
            local Test1 = MergeMany({X = 1}, {X = function(Value)
                return Value + 1
            end})
            expect(Test1.X).to.be.a("function")

            local Test2 = MergeMany({X = 1}, {X = function(Value)
                return Value + 1
            end}, true)
            expect(Test2.X).to.equal(2)

            local Test3 = MergeMany({X = 1}, {X = function(Value)
                return Value + 1
            end}, {X = function(Value)
                return 123
            end}, true)
            expect(Test3.X).to.equal(123)
        end)
    end)
end