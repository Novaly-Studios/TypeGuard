return function()
    local Values = require(script.Parent.Values)

    describe("Shared/Values", function()
        it("should return a blank table given a blank table", function()
            local Result = Values({})
            expect(Result).to.be.ok()
            expect(next(Result)).never.to.be.ok()
        end)

        it("should return one value given a one value table", function()
            local Result = Values({A = 1000})
            expect(table.find(Result, 1000)).to.be.ok()
        end)

        it("should return multiple values given a multiple value table", function()
            local Result = Values({A = 1000, B = 2000, C = true})
            expect(table.find(Result, 1000)).to.be.ok()
            expect(table.find(Result, 2000)).to.be.ok()
            expect(table.find(Result, true)).to.be.ok()
        end)
    end)
end