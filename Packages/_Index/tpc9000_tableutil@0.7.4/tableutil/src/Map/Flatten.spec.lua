return function()
    local Flatten = require(script.Parent.Parent).Map.Flatten

    describe("Map/Flatten", function()
        it("should return a blank table for no data", function()
            local Results = Flatten({})
            expect(next(Results)).never.to.be.ok()
        end)

        it("should return a blank table for a nested series of empty tables", function()
            local Results = Flatten({X = {Y = {}}, Z = {}})
            expect(next(Results)).never.to.be.ok()
        end)

        it("should return the same items given a flat map", function()
            local Results = Flatten({A = 1, B = 2, C = 3})
            expect(Results.A).to.equal(1)
            expect(Results.B).to.equal(2)
            expect(Results.C).to.equal(3)

            local Count = 0

            for _ in Results do
                Count += 1
            end

            expect(Count).to.equal(3)
        end)

        it("should return the primitive items given a nested map", function()
            local Results = Flatten({A = 1, B = {C = 2, D = 3}})
            expect(Results.A).to.equal(1)
            expect(Results.C).to.equal(2)
            expect(Results.D).to.equal(3)

            local Count = 0

            for _ in Results do
                Count += 1
            end

            expect(Count).to.equal(3)
        end)

        it("should return the primitive items given a deeply nested map", function()
            local Results = Flatten({A = 1, B = {C = 2, D = {E = 3, F = 4}}, X = {}, Y = {}})
            expect(Results.A).to.equal(1)
            expect(Results.C).to.equal(2)
            expect(Results.E).to.equal(3)
            expect(Results.F).to.equal(4)

            local Count = 0

            for _ in Results do
                Count += 1
            end

            expect(Count).to.equal(4)
        end)

        it("should return the primitive items given a deeply nested map with arrays", function()
            local Results = Flatten({A = 1, B = {C = 2, D = {E = 3, F = 4}}, X = {}, Y = {}, Z = {1, 2, 3, 4}})
            expect(Results.A).to.equal(1)
            expect(Results.C).to.equal(2)
            expect(Results.E).to.equal(3)
            expect(Results.F).to.equal(4)
            expect(Results[1]).to.equal(1)
            expect(Results[2]).to.equal(2)
            expect(Results[3]).to.equal(3)
            expect(Results[4]).to.equal(4)

            local Count = 0

            for _ in Results do
                Count += 1
            end

            expect(Count).to.equal(8)
        end)

        it("should limit the depth given a 2nd argument", function()
            local Results = Flatten({
                P = 1;
                Q = 2;
                R = 3;

                X = {
                    S = 4;
                    T = 5;
                    U = 6;
                };
            }, 1)

            expect(Results.P).to.equal(1)
            expect(Results.Q).to.equal(2)
            expect(Results.R).to.equal(3)
            expect(Results.S).never.to.be.ok()
            expect(Results.T).never.to.be.ok()
            expect(Results.U).never.to.be.ok()

            Results = Flatten({
                P = 1;
                Q = 2;
                R = 3;

                X = {
                    S = 4;
                    T = 5;
                    U = 6;
                };
            }, 2)

            expect(Results.P).to.equal(1)
            expect(Results.Q).to.equal(2)
            expect(Results.R).to.equal(3)
            expect(Results.S).to.equal(4)
            expect(Results.T).to.equal(5)
            expect(Results.U).to.equal(6)
        end)
    end)
end