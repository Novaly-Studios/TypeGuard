return function()
    local SwapKeysValues = require(script.Parent.SwapKeysValues)

    describe("Shared/SwapKeysValues", function()
        it("should return a blank table for no data", function()
            expect(next(SwapKeysValues({}))).never.to.be.ok()
        end)

        it("should return a single flipped key-value pair for a single item table", function()
            local Result = SwapKeysValues({X = "Y"})

            expect(Result.Y).to.equal("X")
            expect(Result.X).never.to.be.ok()
        end)

        it("should return a flipped key-value pair for each item in the table", function()
            local Result = SwapKeysValues({A = "P", B = "Q", C = "R"})

            expect(Result.P).to.equal("A")
            expect(Result.Q).to.equal("B")
            expect(Result.R).to.equal("C")

            expect(Result.A).never.to.be.ok()
            expect(Result.B).never.to.be.ok()
            expect(Result.C).never.to.be.ok()
        end)
    end)
end