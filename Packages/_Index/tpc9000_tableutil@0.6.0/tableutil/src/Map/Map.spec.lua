return function()
    local Map = require(script.Parent.Map)

    describe("Map/Map", function()
        it("should return a blank array if passed in a blank array", function()
            local Result = Map({}, function(Value, Key)
                return Key, Value
            end)

            expect(next(Result)).to.equal(nil)
        end)

        it("should return all items given a return-same-value function", function()
            local Result = Map({A = 1, B = 2}, function(Value)
                return Value
            end)

            expect(Result.A).to.equal(1)
            expect(Result.B).to.equal(2)
        end)

        it("should pass in keys and allow for custom keys", function()
            local Result = Map({A = 1, B = 2}, function(Value, Key)
                return Value, Key:lower()
            end)

            expect(Result.a).to.equal(1)
            expect(Result.b).to.equal(2)
            expect(Result.A).never.to.be.ok()
            expect(Result.B).never.to.be.ok()
        end)
    end)
end