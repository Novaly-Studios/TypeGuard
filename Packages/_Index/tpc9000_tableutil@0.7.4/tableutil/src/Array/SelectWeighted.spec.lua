return function()
    local SelectWeighted = require(script.Parent.Parent).Array.SelectWeighted

    local WeightTable = {
        {ID = "P", Weight = 10};
        {ID = "Q", Weight = 10};
        {ID = "R", Weight = 30};
        {ID = "S", Weight = 5};
        {ID = "T", Weight = 5};
        {ID = "U", Weight = 15};
        {ID = "V", Weight = 25};
    }

    describe("Array/SelectWeighted", function()
        it("should always select a weighted value", function()
            for _ = 1, 1000000 do
                expect(SelectWeighted(WeightTable, "Weight")).to.be.ok()
            end
        end)

        it("should select the same weighted value with a seed", function()
            local Last

            for _ = 1, 1000000 do
                local Temp = SelectWeighted(WeightTable, "Weight", 1)

                if (Last) then
                    expect(Temp).to.equal(Last)
                end

                Last = Temp
            end
        end)

        it("should produce distributions similar to the weights", function()
            local Results = {}

            for _ = 1, 1000000 do
                local Value = SelectWeighted(WeightTable, "Weight")
                Results[Value.ID] = (Results[Value.ID] or 0) + 1
            end

            expect(Results.P).to.be.near(1000000 * 0.1, 1000000 * 0.1 * 0.1)
            expect(Results.Q).to.be.near(1000000 * 0.1, 1000000 * 0.1 * 0.1)
            expect(Results.R).to.be.near(1000000 * 0.3, 1000000 * 0.3 * 0.1)
            expect(Results.S).to.be.near(1000000 * 0.05, 1000000 * 0.05 * 0.1)
            expect(Results.T).to.be.near(1000000 * 0.05, 1000000 * 0.05 * 0.1)
            expect(Results.U).to.be.near(1000000 * 0.15, 1000000 * 0.15 * 0.1)
            expect(Results.V).to.be.near(1000000 * 0.25, 1000000 * 0.25 * 0.1)
        end)
    end)
end