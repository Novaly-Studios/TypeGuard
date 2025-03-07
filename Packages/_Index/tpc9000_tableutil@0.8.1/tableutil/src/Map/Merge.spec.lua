return function()
    local Merge = require(script.Parent.Parent).Map.Merge

    describe("Map/Merge", function()
        it("should functionally merge two maps together", function()
            local Result = Merge({X = 1}, {Y = 2})
            expect(Result).to.be.a("table")
            expect(Result.X).to.equal(1)
            expect(Result.Y).to.equal(2)
        end)

        it("should overwrite existing non-table values with tables", function()
            local Result = Merge({X = false}, {X = {}})
            expect(Result).to.be.a("table")
            expect(Result.X).to.be.a("table")
        end)

        it("should return the left table when the right table is blank", function()
            local X = {X = 1, Y = 2}
            local Y = {}

            -- Passing in an unfrozen table on right side -> it should copy the left side (X) and return.
            local Result = Merge(X, Y)
            expect(Result).to.be.a("table")
            expect(Result).never.to.equal(X)
            expect(Result).never.to.equal(Y)
            expect(Result.X).to.equal(1)
            expect(Result.Y).to.equal(2)

            -- Now freeze, it can directly return X.
            table.freeze(X)
            Result = Merge(X, Y)
            expect(Result).to.be.a("table")
            expect(Result).to.equal(X)
            expect(Result).never.to.equal(Y)
        end)

        it("should return the right table when the left table is blank", function()
            local X = {}
            local Y = {X = 1, Y = 2}

            -- Passing in an unfrozen table on left side -> it should copy the right side (Y) and return.
            local Result = Merge(X, Y)
            expect(Result).to.be.a("table")
            expect(Result).never.to.equal(X)
            expect(Result).never.to.equal(Y)
            expect(Result.X).to.equal(1)
            expect(Result.Y).to.equal(2)

            -- Now freeze, it can directly return Y.
            table.freeze(Y)
            Result = Merge(X, Y)
            expect(Result).to.be.a("table")
            expect(Result).never.to.equal(X)
            expect(Result).to.equal(Y)
        end)

        it("should use functions to overwrite old values with new values, only if the final arg is set to true", function()
            local function Increment(Value)
                return Value + 1
            end

            -- No final arg passed.
            local Result = Merge({X = 1}, {X = Increment})
            expect(Result).to.be.a("table")
            expect(Result.X).to.be.a("function")

            -- Final arg as true -> it should use mapper functions.
            Result = Merge({X = 1}, {X = Increment}, true)
            expect(Result).to.be.a("table")
            expect(Result.X).to.equal(2)
        end)

        it("should overwrite left side table's metatable with the right side's metatable if different", function()
            local MT1 = {
                __gt = function() end;
            }
            local MT2 = {
                __gt = function() end;
            }
            local X = setmetatable({}, MT1)
            local Y = {}

            -- No metatable, merged into X.
            local Result = Merge(X, Y)
            expect(Result).to.be.a("table")
            expect(getmetatable(Result)).to.equal(MT1)

            -- MT2, merged into X.
            setmetatable(Y, MT2)
            Result = Merge(X, Y)
            expect(Result).to.be.a("table")
            expect(getmetatable(Result)).to.equal(MT2)
        end)
    end)
end