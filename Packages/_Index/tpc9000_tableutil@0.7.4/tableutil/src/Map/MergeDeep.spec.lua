return function()
    local MergeDeep = require(script.Parent.Parent).Map.MergeDeep

    describe("Map/MergeDeep", function()
        it("should return the same table for two equivalent merged tables", function()
            local Test = {}
            local Result = MergeDeep(Test, Test)
            expect(Result).to.be.a("table")
            expect(Result).to.equal(Test)
        end)

        it("should merge some flat values in and return a new table", function()
            local X = {
                A = 1;
                B = 2;
            }
            local Y = {
                C = 3;
                D = 4;
            }

            local Result = MergeDeep(X, Y)
            expect(Result).to.be.a("table")
            expect(Result.A).to.equal(1)
            expect(Result.B).to.equal(2)
            expect(Result.C).to.equal(3)
            expect(Result.D).to.equal(4)
            expect(X).never.to.equal(Result)
            expect(Y).never.to.equal(Result)
        end)

        it("should merge two nested values together and return create new tables for modified levels", function()
            local X = {
                P = 1;
                Q = {
                    R = 2;
                };
            }
            local Y = {
                Q = {
                    S = 3;
                };
            }

            local Result = MergeDeep(X, Y)
            expect(Result).to.be.a("table")
            expect(Result.P).to.equal(1)
            expect(Result.Q).to.be.a("table")
            expect(Result.Q.R).to.equal(2)
            expect(Result.Q.S).to.equal(3)
            expect(Result.Q).never.to.equal(X.Q)
            expect(Result.Q).never.to.equal(Y.Q)

            local Reverse = MergeDeep(Y, X)
            expect(Reverse).to.be.a("table")
            expect(Reverse.P).to.equal(1)
            expect(Reverse.Q).to.be.a("table")
            expect(Reverse.Q.R).to.equal(2)
            expect(Reverse.Q.S).to.equal(3)
            expect(Reverse.Q).never.to.equal(X.Q)
            expect(Reverse.Q).never.to.equal(Y.Q)
        end)

        it("should keep unmodified sub-tables untouched", function()
            local X = {
                A = {};
                B = {
                    Test = true;
                };
            }
            local Y = {
                B = {
                    C = {};
                };
            }

            local Result = MergeDeep(X, Y)
            expect(Result).to.be.a("table")
            expect(Result.A).to.equal(X.A)
            expect(Result.B).to.be.a("table")
            expect(Result.B.Test).to.equal(true)
            expect(Result.B.C).to.be.a("table")
            expect(Result.B).never.to.equal(X.B)
            expect(Result.B).never.to.equal(Y.B)
            expect(Result.B.C).to.equal(Y.B.C)
        end)

        it("should return the original table when both tables are the same", function()
            local X = {P = true, Q = true, R = true}
            local Y = X

            local Result = MergeDeep(X, Y)
            expect(Result).to.equal(X)
            expect(Result).to.equal(Y)
        end)

        it("should preserve left-side metatables when the right-side has no metatable", function()
            local MT = {__len = function() end}

            -- With values inside.
            local Result = MergeDeep({
                Test = {
                    Test = setmetatable({Value1 = 1}, MT);
                };
            }, {
                Test = {
                    Test = {Value2 = 2};
                };
            })
            expect(getmetatable(Result.Test.Test)).to.equal(MT)

            -- With no values inside.
            Result = MergeDeep({
                Test = {
                    Test = setmetatable({}, MT);
                };
            }, {
                Test = {
                    Test = {};
                };
            })
            expect(getmetatable(Result.Test.Test)).to.equal(MT)
        end)

        it("should overwrite left-side metatables with right-side metatables", function()
            local MT = {__len = function() end}
            local MT2 = {__len = function() end}

            -- With values inside.
            local Result = MergeDeep({
                Test = {
                    Test = setmetatable({Value1 = 1}, MT);
                };
            }, {
                Test = {
                    Test = setmetatable({Value2 = 2}, MT2);
                };
            })
            expect(getmetatable(Result.Test.Test)).to.equal(MT2)

            -- With no values inside.
            local X = {
                Test = {
                    Test = setmetatable({}, MT);
                };
            }
            local Y = {
                Test = {
                    Test = setmetatable({}, MT2);
                };
            }
            Result = MergeDeep(X, Y)
            expect(getmetatable(Result.Test.Test)).to.equal(MT2)
            expect(Result.Test.Test).never.to.equal(X.Test)
            expect(Result.Test.Test).never.to.equal(Y.Test)
        end)

        it("should preserve right-side metatables when a new value is added", function()
            local MT = {__len = function() end}

            -- With values inside.
            local Result = MergeDeep({Value1 = 1}, {
                Test = {
                    Test = setmetatable({Value2 = 2}, MT);
                };
            })
            expect(getmetatable(Result.Test.Test)).to.equal(MT)

            -- With no values inside.
            Result = MergeDeep({}, {
                Test = {
                    Test = setmetatable({}, MT);
                };
            })
            expect(getmetatable(Result.Test.Test)).to.equal(MT)
        end)

        it("should pass the left-side value for mapping into a right-side function when FunctionalAppliers is true", function()
            local Result = MergeDeep({
                Inner = {
                    X = 1;
                    Y = 2;
                };
            }, {
                Inner = {
                    Y = function(Value)
                        return 1000 + Value
                    end;
                };
            })

            expect(Result.Inner.X).to.equal(1)
            expect(Result.Inner.Y).to.equal(1002)
        end)

        it("should propagate the change up the structure but keep unchanged nodes equal", function()
            local Base = {X = {Y = {Value = 1}, Z = {Value = 22}}}
            local Result = MergeDeep(Base, {X = {Y = {Value = 2}, Z = {Value = 22}}})
            expect(Result).never.to.equal(Base)
            expect(Base.X.Z).to.equal(Result.X.Z)
        end)

        it("should produce unequal tables if the right-side metatable is different", function()
            local Base = {}
            local Result = MergeDeep(Base, setmetatable({}, {}))
            expect(Result).never.to.equal(Base)
        end)

        it("should result in equal tables given equal values, under right side no metatable and left side has metatable condition", function()
            local Base = {Test = setmetatable({}, {})}
            local Result = MergeDeep(Base, {Test = {}})
            expect(Result).to.equal(Base)
        end)
    end)
end