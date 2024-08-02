return function()
    local FromValues = require(script.Parent.FromValues)

    describe("Set/FromValues", function()
        it("should return an empty table given an empty table", function()
            local Result = FromValues({})
            expect(next(Result)).never.to.be.ok()
        end)

        it("should return correctly for one item", function()
            local Result = FromValues({A = "1234"})
            expect(Result["1234"]).to.be.ok()
        end)

        it("should return correctly for multiple items", function()
            local Result = FromValues({A = "1", B = "2", C = "3"})
            expect(Result["1"]).to.be.ok()
            expect(Result["2"]).to.be.ok()
            expect(Result["3"]).to.be.ok()
        end)
    end)
end