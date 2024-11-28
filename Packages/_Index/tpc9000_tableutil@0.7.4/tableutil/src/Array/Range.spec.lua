return function()
    local Range = require(script.Parent.Parent).Array.Range

    describe("Array/Range", function()
        it("should return a single element list for a range of 1", function()
            local Test = Range(1, 1)
            expect(Test).to.be.a("table")
            expect(#Test).to.equal(1)
            expect(Test[1]).to.equal(1)
        end)

        it("should return correctly incremented values for a range of 2", function()
            local Result = Range(1, 4)
            expect(Result[1]).to.equal(1)
            expect(Result[2]).to.equal(2)
            expect(Result[3]).to.equal(3)
            expect(Result[4]).to.equal(4)
        end)

        it("should throw an error if min is greater than max", function()
            expect(function()
                Range(2, 1)
            end).to.throw()
        end)
    end)
end