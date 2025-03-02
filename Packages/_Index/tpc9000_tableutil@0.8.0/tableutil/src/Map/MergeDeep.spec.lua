return function()
    local MergeDeep = require(script.Parent.Parent).Map.MergeDeep

    describe("Map/MergeDeep", function()
        it("should functionally merge two maps together", function()
            local Result = MergeDeep({X = 1, Z = {}}, {Y = 2, Z = {Value = 3}})
            expect(Result).to.be.a("table")
            expect(Result.X).to.equal(1)
            expect(Result.Y).to.equal(2)
            expect(Result.Z).to.be.a("table")
            expect(Result.Z.Value).to.equal(3)
        end)

        it("should overwrite existing non-table values with tables", function()
            local Result = MergeDeep({X = false, Y = {Z = 123}}, {X = {}, Y = {Z = {}}})
            expect(Result).to.be.a("table")
            expect(Result.X).to.be.a("table")
            expect(Result.Y).to.be.a("table")
            expect(Result.Y.Z).to.be.a("table")
        end)

        it("should return the left table when the right table is blank", function()
            local X = {Inner1 = {Inner2 = {X = 1, Y = 2}}}
            local Y = {Inner1 = {Inner2 = {}}}

            -- Passing in an unfrozen table on right side -> it should copy the left side (X) and return.
            local Result = MergeDeep(X, Y)
            expect(Result).to.be.a("table")
            expect(Result.Inner1).to.be.a("table")
            expect(Result.Inner1.Inner2).to.be.a("table")
            expect(Result.Inner1.Inner2).never.to.equal(X.Inner1.Inner2)
            expect(Result.Inner1.Inner2).never.to.equal(Y.Inner1.Inner2)
            expect(Result.Inner1.Inner2.X).to.equal(1)
            expect(Result.Inner1.Inner2.Y).to.equal(2)

            -- Now freeze, it can directly return X.
            X = table.freeze({Inner1 = table.freeze({Inner2 = table.freeze({X = 1, Y = 2})})})
            Y = table.freeze({Inner1 = table.freeze({Inner2 = table.freeze({})})})
            Result = MergeDeep(X, Y)
            expect(Result).to.be.a("table")
            expect(Result).to.equal(X)
        end)

        it("should return the right table when the left table is blank", function()
            local X = {Inner = {}}
            local Y = {Inner = {X = 1, Y = 2}}

            -- Passing in an unfrozen table on left side -> it should copy the right side (Y) and return.
            local Result = MergeDeep(X, Y)
            expect(Result).to.be.a("table")
            expect(Result.Inner).to.be.a("table")
            expect(Result.Inner).never.to.equal(X.Inner)
            expect(Result.Inner).never.to.equal(Y.Inner)
            expect(Result.Inner.X).to.equal(1)
            expect(Result.Inner.Y).to.equal(2)

            -- Now freeze, it can directly return Y.
            Y = table.freeze({Inner = table.freeze({X = 1, Y = 2})})
            Result = MergeDeep(X, Y)
            expect(Result).to.be.a("table")
            expect(Result.Inner).to.be.a("table")
            expect(Result.Inner).to.equal(Y.Inner)
        end)

        it("should use functions to overwrite old values with new values, only if the final arg is set to true", function()
            local function Increment(Value)
                return Value + 1
            end

            -- No final arg passed.
            local Result = MergeDeep({X = {Y = 1}}, {X = {Y = Increment}})
            expect(Result).to.be.a("table")
            expect(Result.X).to.be.a("table")
            expect(Result.X.Y).to.be.a("function")

            -- Final arg as true -> it should use mapper functions.
            Result = MergeDeep({X = {Y = 1}}, {X = {Y = Increment}}, true)
            expect(Result).to.be.a("table")
            expect(Result.X).to.be.a("table")
            expect(Result.X.Y).to.equal(2)
        end)

        it("should overwrite left side table's metatable with the right side's metatable if different", function()
            local MT1 = {
                __gt = function() end;
            }
            local MT2 = {
                __gt = function() end;
            }
            local X = {Inner = setmetatable({}, MT1)}
            local Y = {Inner = {}}

            -- No metatable, merged into X.
            local Result = MergeDeep(X, Y)
            expect(Result).to.be.a("table")
            expect(Result.Inner).to.be.a("table")
            expect(getmetatable(Result.Inner)).to.equal(MT1)

            -- MT2, merged into X.
            setmetatable(Y.Inner, MT2)
            Result = MergeDeep(X, Y)
            expect(Result).to.be.a("table")
            expect(Result.Inner).to.be.a("table")
            expect(getmetatable(Result.Inner)).to.equal(MT2)
        end)
    end)
end