return function()
    local SelectFirst = require(script.Parent.Parent).Array.SelectFirst

    describe("Array/SelectFirst", function()
        it("should select nothing on an empty array", function()
            expect(SelectFirst({}, function() end)).never.to.be.ok()
        end)

        it("should select the first item in an array for a return-true function", function()
            expect(SelectFirst({1}, function()
                return true
            end)).to.equal(1)
        end)

        it("should select the first item greater than some number", function()
            expect(SelectFirst({1, 2, 4, 8, 16, 32}, function(Value)
                return Value >= 8
            end)).to.equal(8)
        end)

        it("should select the first index greater than some number", function()
            expect(SelectFirst({1, 2, 4, 8, 16, 32}, function(_, Index)
                return Index >= 3
            end)).to.equal(4)
        end)

        it("should return the index of the first matched value", function()
            local _, index = SelectFirst({1, 2, 3, 4, 5, 6}, function(Value)
                return Value % 2 == 0
            end)

            expect(index).to.equal(2)
        end)
    end)
end