return function()
    local SelectRandom = require(script.Parent.SelectRandom)

    describe("Array/SelectRandom", function()
        it("should return nil for an empty array", function()
            expect(SelectRandom({})).to.equal(nil)
        end)

        it("should return the only item in a one-item array", function()
            local Value, Key = SelectRandom({X = 1})
            expect(Value).to.equal(1)
            expect(Key).to.equal("X")
        end)

        it("should return a random item in a two-item array", function()
            local Array = {X = 1, Y = 2}
            local Value, Key = SelectRandom(Array)
            assert(Key == "X" or Key == "Y")
            assert(Value == 1 or Value == 2)
        end)

        it("should accept a seed which selects the same item each time", function()
            local RNG = Random.new(100)
            local Map = {}

            for _ = 1, 10_000 do
                Map[string.char(RNG:NextInteger(0, 255), RNG:NextInteger(0, 255), RNG:NextInteger(0, 255))] = RNG:NextNumber()
            end

            local Result1 = SelectRandom(Map, 1)
            local Result2 = SelectRandom(Map, 1)
            local Result3 = SelectRandom(Map, 1)
            expect(Result1 == Result2 and Result2 == Result3).to.equal(true)
        end)
    end)
end