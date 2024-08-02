return function()
    local FromKeyValueArray = require(script.Parent.FromKeyValueArray)

    describe("Map/FromKeyValueArray", function()
        it("should return a blank map given an empty array", function()
            expect(next(FromKeyValueArray({}))).never.to.be.ok()
        end)

        it("should create a map with one key-value pair", function()
            local Result = FromKeyValueArray({{Key = "A", Value = 1}})
            expect(Result.A).to.equal(1)
        end)

        it("should create a map with key-value pairs", function()
            local Result = FromKeyValueArray({{Key = "A", Value = 1}, {Key = "B", Value = 2}, {Key = "C", Value = 3}})
            expect(Result.A).to.equal(1)
            expect(Result.B).to.equal(2)
            expect(Result.C).to.equal(3)
        end)
    end)
end