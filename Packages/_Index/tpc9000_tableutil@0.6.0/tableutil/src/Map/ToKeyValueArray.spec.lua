return function()
    local ToKeyValueArray = require(script.Parent.ToKeyValueArray)

    describe("Map/ToKeyValueArray", function()
        it("should return a blank array given an empty table", function()
            expect(#ToKeyValueArray({})).to.equal(0)
        end)

        it("should return a single key-value pair for a single item table", function()
            local Result = ToKeyValueArray({A = 1})
            expect(#Result).to.equal(1)
            expect(Result[1].Key).to.equal("A")
            expect(Result[1].Value).to.equal(1)
        end)

        it("should return a key-value pair for each item in the table", function()
            local Result = ToKeyValueArray({A = 1, B = 2, C = 3})
            expect(#Result).to.equal(3)

            local function Satisfied(Condition)
                for _, Value in Result do
                    if (Condition(Value)) then
                        return true
                    end
                end

                return false
            end

            expect(Satisfied(function(Value)
                return Value.Key == "A" and Value.Value == 1
            end)).to.equal(true)

            expect(Satisfied(function(Value)
                return Value.Key == "B" and Value.Value == 2
            end)).to.equal(true)

            expect(Satisfied(function(Value)
                return Value.Key == "C" and Value.Value == 3
            end)).to.equal(true)
        end)
    end)
end