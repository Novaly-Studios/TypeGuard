return function()
    local SelectLast = require(script.Parent.SelectLast)

    describe("Array/SelectLast", function()
        it("should select nothing on an empty array", function()
            expect(SelectLast({}, function() end)).never.to.be.ok()
        end)

        it("should select the last item in an array for a return-true function", function()
            expect(SelectLast({1}, function()
                return true
            end)).to.equal(1)
        end)

        it("should select the last item greater than some number", function()
            expect(SelectLast({1, 2, 4, 8, 16, 32}, function(Value)
                return Value >= 8
            end)).to.equal(32)
        end)

        it("should select the last index greater than some number", function()
            expect(SelectLast({1, 2, 4, 8, 16, 32}, function(_, Index)
                return Index >= 3
            end)).to.equal(32)
        end)

        it("should return the index of the last matched value", function()
            local _, index = SelectLast({1, 2, 3, 4, 5, 6}, function(Value)
                return Value % 2 == 0
            end)

            expect(index).to.equal(6)
        end)
    end)
end