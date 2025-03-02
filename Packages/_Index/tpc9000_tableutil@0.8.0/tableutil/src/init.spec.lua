return function()
    local TableUtil = require(script.Parent)

    describe("WithFeatures", function()
        it("should cache irrespective of the order of the feature strings", function()
            local All = TableUtil.WithFeatures("Assert", "Freeze")
            expect(All == TableUtil.WithFeatures("Freeze", "Assert")).to.equal(true)
            expect(TableUtil.WithFeatures("Assert") == TableUtil.WithFeatures("Assert")).to.equal(true)
            expect(TableUtil.WithFeatures("Freeze") == TableUtil.WithFeatures("Freeze")).to.equal(true)
            expect(All == TableUtil.WithFeatures("Freeze")).to.equal(false)
        end)

        it("should apply nothing if no features are enabled", function()
            local Library = TableUtil.WithFeatures()
            expect(table.isfrozen(Library.Array.Filter({1, 2, 3}, function()
                return true
            end))).to.equal(false)
        end)
    end)
end