return function()
    local Map = require(script.Parent.Parent).Map.Map

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

        it("should return the same table if values are the same", function()
            local Base = {A = 1, B = 2}
            local Result = Map(Base, function(Value)
                return Value
            end)
            expect(Result).to.equal(Base)
        end)

        it("should return a new table if values are different", function()
            local Base = {A = 1, B = 2}
            local Result = Map(Base, function(Value)
                return Value + 1
            end)
            expect(Result).to.be.a("table")
            expect(Result).never.to.equal(Base)
            expect(Result.A).to.equal(2)
            expect(Result.B).to.equal(3)
        end)

        it("should return a new table if keys are different", function()
            local Base = {A = 1, B = 2}
            local Result = Map(Base, function(Value, Key)
                return Value, (Key == "A" and "C" or Key)
            end)
            expect(Result).to.be.a("table")
            expect(Result).never.to.equal(Base)
            expect(Result.A).to.equal(nil)
            expect(Result.C).to.equal(1)
            expect(Result.B).to.equal(2)
        end)
    end)
end