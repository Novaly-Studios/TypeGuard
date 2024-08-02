return function()
    local MergeDeep = require(script.Parent.MergeDeep)

    describe("Map/MergeDeep", function()
        it("should return the second table for two merged blank tables", function()
            local X = {}
            local Y = {}

            local Result = MergeDeep(X, Y)
            expect(Result).to.be.a("table")
            expect(next(Result)).to.equal(nil)
            expect(Y).to.equal(Result)

            local Reverse = MergeDeep(Y, X)
            expect(Reverse).to.be.a("table")
            expect(next(Reverse)).to.equal(nil)
            expect(X).to.equal(Reverse)
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
    end)
end