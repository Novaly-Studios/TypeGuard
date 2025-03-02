return function()
    local MutableMergeDeep = require(script.Parent.Parent).Map.MutableMergeDeep

    describe("Map/MutableMergeDeep", function()
        it("should not modify a blank table given a blank table to merge in", function()
            local Result = {}
            MutableMergeDeep(Result, {})
            expect(next(Result)).never.to.be.ok()
        end)

        it("should flat modify a table given a single item table to merge in", function()
            local Result = {}
            MutableMergeDeep(Result, {A = 1})
            expect(Result.A).to.equal(1)
        end)

        it("should flat modify a table given a multiple item table to merge in", function()
            local Result = {}
            MutableMergeDeep(Result, {A = 1, B = 2, C = 3})
            expect(Result.A).to.equal(1)
            expect(Result.B).to.equal(2)
            expect(Result.C).to.equal(3)
        end)

        it("should overwrite the former table", function()
            local Result = {A = 1, B = 2}
            MutableMergeDeep(Result, {B = 4})
            expect(Result.A).to.equal(1)
            expect(Result.B).to.equal(4)
        end)

        it("should merge tables recursively", function()
            local Result = {X = {}, Y = {}}
            local MergeIn1 = {X = {Value = 1}}
            local MergeIn2 = {Y = {Value = 2}}

            MutableMergeDeep(Result, MergeIn1)
            MutableMergeDeep(Result, MergeIn2)

            expect(Result.X.Value).to.equal(1)
            expect(Result.Y.Value).to.equal(2)

            expect(Result.X).never.to.equal(MergeIn1.X)
            expect(Result.Y).never.to.equal(MergeIn2.Y)
        end)

        it("should preserve a metatable on the left-side table with a non-metatable on the right-side table", function()
            local MT = {__gt = function() return false end}
            local Left = {Test = setmetatable({A = 1, B = 2}, MT)}
            local Right = {Test = {C = 3, D = 4}}
            MutableMergeDeep(Left, Right)
            expect(getmetatable(Left.Test)).to.equal(MT)
        end)

        it("should overwrite a left-side metatable with a right-side metatable", function()
            local MT = {__gt = function() return false end}
            local MT2 = {__gt = function() return false end}
            local Left = {Test = setmetatable({A = 1, B = 2}, MT)}
            local Right = {Test = setmetatable({C = 3, D = 4}, MT2)}
            MutableMergeDeep(Left, Right)
            expect(getmetatable(Left.Test)).to.equal(MT2)
        end)

        it("should apply mapper functions to right-side values when enabled", function()
            local Test1 = {X = 1, Y = {Z = 2}}
            MutableMergeDeep(Test1, {
                Y = {
                    Z = function(Value)
                        return 1000 + Value
                    end;
                };
            })
            expect(Test1.Y.Z).to.be.a("function")

            local Test2 = {X = 1, Y = {Z = 2}}
            MutableMergeDeep(Test2, {
                Y = {
                    Z = function(Value)
                        return 1000 + Value
                    end;
                };
            }, true)
            expect(Test2.Y.Z).to.equal(1002)
        end)

        it("should correctly substitute in nil values with mapper functions", function()
            local Test = {X = {Y = 1}}
            MutableMergeDeep(Test, {
                X = {
                    Y = function()
                        return nil
                    end;
                };
            }, true)
            expect(Test.X.Y).to.equal(nil)
        end)
        
        it("should overwrite primitive values with a table", function()
            local Result = {X = false, Y = 123}
            MutableMergeDeep(Result, {X = {Value = 1}, Y = {Value = 2}})
            expect(Result.X).to.be.a("table")
            expect(Result.X.Value).to.equal(1)
            expect(Result.Y).to.be.a("table")
            expect(Result.Y.Value).to.equal(2)
        end)
    end)
end