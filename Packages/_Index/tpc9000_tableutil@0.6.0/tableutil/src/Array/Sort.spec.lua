return function()
    local Sort = require(script.Parent.Sort)

    describe("Array/Sort", function()
        it("should return an empty array given an empty array", function()
            local Result = Sort({})
            expect(next(Result)).to.equal(nil)
        end)

        it("should return a one-item array given a one-item array", function()
            local Result = Sort({1})
            expect(Result[1]).to.equal(1)
        end)

        it("should sort ascending given an ascending function", function()
            local Result = Sort({4, 8, 1, 2}, function(Initial, Other)
                return Initial < Other
            end)

            expect(Result[1]).to.equal(1)
            expect(Result[2]).to.equal(2)
            expect(Result[3]).to.equal(4)
            expect(Result[4]).to.equal(8)
        end)

        it("should sort descending given an ascending function", function()
            local Result = Sort({4, 8, 1, 2}, function(Initial, Other)
                return Initial > Other
            end)

            expect(Result[1]).to.equal(8)
            expect(Result[2]).to.equal(4)
            expect(Result[3]).to.equal(2)
            expect(Result[4]).to.equal(1)
        end)
    end)
end