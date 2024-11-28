return function()
    local MergeMany = require(script.Parent.Parent).Map.MergeMany

    describe("Map/MergeMany", function()
        it("should return a blank table for no inputs", function()
            local Result = MergeMany()
            expect(next(Result)).never.to.be.ok()
        end)

        it("should return a blank table for one blank table input", function()
            local Result = MergeMany({})
            expect(next(Result)).never.to.be.ok()
        end)

        it("should return a blank table for multiple blank table inputs", function()
            local Result = MergeMany({}, {}, {}, {})
            expect(next(Result)).never.to.be.ok()
        end)

        it("should merge two tables", function()
            local Result = MergeMany({A = 1, B = 2}, {C = 3})
            expect(Result.A).to.equal(1)
            expect(Result.B).to.equal(2)
            expect(Result.C).to.equal(3)
        end)

        it("should overwrite former tables", function()
            local Result = MergeMany({A = 1, B = 2}, {B = 3}, {B = 4})
            expect(Result.A).to.equal(1)
            expect(Result.B).to.equal(4)
        end)

        it("should merge several tables", function()
            local Result = MergeMany({A = 1, B = 2}, {C = 3}, {D = 4})
            expect(Result.A).to.equal(1)
            expect(Result.B).to.equal(2)
            expect(Result.C).to.equal(3)
            expect(Result.D).to.equal(4)
        end)

        it("should allow left-hand metatables to be overwriten by right-hand metatables", function()
            local MT1 = {__len = function() end}
            local MT2 = {__len = function() end}
            local MT3 = {__len = function() end}

            local Result = MergeMany(
                setmetatable({A = 1}, MT1),
                setmetatable({B = 2}, MT2),
                setmetatable({C = 3}, MT3)
            )

            expect(Result).to.be.ok()
            expect(Result).to.be.a("table")
            expect(getmetatable(Result)).to.equal(MT3)
            expect(Result.A).to.equal(1)
            expect(Result.B).to.equal(2)
            expect(Result.C).to.equal(3)
        end)

        it("should preserve left-side metatables when right-side has no metatable", function()
            local MT1 = {__len = function() end}
            local Result = MergeMany(
                setmetatable({Value1 = 1}, MT1),
                {Value2 = 2}
            )
            expect(getmetatable(Result)).to.equal(MT1)
            expect(Result.Value1).to.equal(1)
            expect(Result.Value2).to.equal(2)
        end)
    end)
end