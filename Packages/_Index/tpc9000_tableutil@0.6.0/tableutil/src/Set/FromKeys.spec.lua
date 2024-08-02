return function()
    local FromKeys = require(script.Parent.FromKeys)

    describe("Set/FromKeys", function()
        it("should return an empty table given an empty table", function()
            local Result = FromKeys({})
            expect(next(Result)).never.to.be.ok()
        end)

        it("should return correctly for one item", function()
            local Result = FromKeys({A = 1234})
            expect(Result.A).to.be.ok()
        end)

        it("should return correctly for multiple items", function()
            local Result = FromKeys({A = 1, B = 2, C = 3})
            expect(Result.A).to.be.ok()
            expect(Result.B).to.be.ok()
            expect(Result.C).to.be.ok()
        end)
    end)
end