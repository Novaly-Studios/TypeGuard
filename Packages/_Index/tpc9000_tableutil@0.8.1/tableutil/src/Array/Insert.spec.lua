return function()
    local Insert = require(script.Parent.Parent).Array.Insert

    describe("Array/Insert", function()
        it("should insert an item in the first position in an empty array", function()
            local Result = Insert({}, 1)

            expect(Result[1]).to.be.ok()
            expect(Result[1]).to.equal(1)
        end)

        it("should insert two items in order into an empty array", function()
            local Result = {}
            Result = Insert(Insert(Result, 1), 2)

            for Index = 1, 2 do
                expect(Result[Index]).to.be.ok()
                expect(Result[Index]).to.equal(Index)
            end
        end)

        it("should allow insertion at an inner index", function()
            local Result = {1, 2, 4, 5}
            Result = Insert(Result, 3, 3)

            for Index = 1, 5 do
                expect(Result[Index]).to.be.ok()
                expect(Result[Index]).to.equal(Index)
            end
        end)

        it("should allow insertion at index 1", function()
            local Result = {2, 3}
            Result = Insert(Result, 1, 1)

            for Index = 1, 3 do
                expect(Result[Index]).to.be.ok()
                expect(Result[Index]).to.equal(Index)
            end
        end)

        it("should disallow insertion at index length+2", function()
            expect(function()
                Insert({1, 2}, 1000, 4, true)
            end).to.throw()
        end)

        it("should return the original array if the new value is being appended to the end and is nil, if the table is frozen", function()
            local Test = table.freeze({1, 2, 3})
            local Result = Insert(Test, nil)
            expect(Result).to.equal(Test)

            Result = Insert(Test, nil, 4)
            expect(Result).to.equal(Test)
        end)

        it("should return a copy of the original array if the new value is being appended to the end and is nil, if the table is not frozen", function()
            local Test = {1, 2, 3}
            local Result = Insert(Test, nil)
            expect(Result).never.to.equal(Test)
        end)
    end)
end