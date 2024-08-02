return function()
    local Keys = require(script.Parent.Keys)

    describe("Map/Keys", function()
        it("should return a blank table given a blank table", function()
            local Result = Keys({})
            expect(Result).to.be.ok()
            expect(next(Result)).never.to.be.ok()
        end)

        it("should return one key given a one key table", function()
            local Result = Keys({A = 1000})
            expect(table.find(Result, "A")).to.be.ok()
        end)

        it("should return multiple keys given a multiple key table", function()
            local Result = Keys({A = 1000, B = 2000, C = true})
            expect(table.find(Result, "A")).to.be.ok()
            expect(table.find(Result, "B")).to.be.ok()
            expect(table.find(Result, "C")).to.be.ok()
        end)
    end)
end