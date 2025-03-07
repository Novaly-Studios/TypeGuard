return function()
    local MutableBinaryInsert = require(script.Parent.Parent).Array.MutableBinaryInsert

    describe("Array/MutableBinaryInsert", function()
        it("should insert into the first index of an empty array", function()
            local Array = {}
            MutableBinaryInsert(Array, 1)
            expect(Array[1]).to.equal(1)
        end)

        it("should insert into the first index of a one-item array", function()
            local Array = {2}
            MutableBinaryInsert(Array, 1)
            expect(Array[1]).to.equal(1)
            expect(Array[2]).to.equal(2)
        end)

        it("should insert into the second index of a one-item array", function()
            local Array = {1}
            MutableBinaryInsert(Array, 2)
            expect(Array[1]).to.equal(1)
            expect(Array[2]).to.equal(2)
        end)

        it("should insert into the first index of a two-item array", function()
            local Array = {3, 4}
            MutableBinaryInsert(Array, 1)
            expect(Array[1]).to.equal(1)
            expect(Array[2]).to.equal(3)
            expect(Array[3]).to.equal(4)
        end)

        it("should insert various random numbers, creating an ordered array", function()
            local Array = {}
            local Random = Random.new()

            for _ = 1, 100 do
                MutableBinaryInsert(Array, Random:NextInteger(1, 10))
            end

            for Index = 2, #Array do
                expect(Array[Index - 1] <= Array[Index]).to.equal(true)
            end
        end)
    end)
end