return function()
    local Set = require(script.Parent.Parent).Set
        local FromValues = Set.FromValues
        local Insert = Set.Insert

    describe("Set/Insert", function()
        it("should return the same set given a nil value if frozen", function()
            local Sample1 = {}
            expect(Insert(Sample1, nil)).to.never.equal(Sample1)

            local Sample2 = {[1] = true, [2] = true, [3] = true}
            expect(Insert(Sample2, nil)).to.never.equal(Sample2)

            table.freeze(Sample1)
            table.freeze(Sample2)

            expect(Insert(Sample1, nil)).to.equal(Sample1)
            expect(Insert(Sample2, nil)).to.equal(Sample2)
        end)

        it("should return a new set with the given value", function()
            local Sample = FromValues({})
            local Result = Insert(Sample, 1)
            expect(Result).never.to.equal(Sample)
            expect(Result[1]).to.equal(true)
        end)

        it("should return the same set given a value already in the set", function()
            local Sample = FromValues({1, 2, 3})
            expect(Insert(Sample, 2)).to.equal(Sample)
        end)

        it("should return a new set with the given value for a non-empty set", function()
            local Sample = FromValues({1, 2, 3})
            local Result = Insert(Sample, 4)
            expect(Result).never.to.equal(Sample)
            expect(Result[1]).to.equal(true)
            expect(Result[2]).to.equal(true)
            expect(Result[3]).to.equal(true)
            expect(Result[4]).to.equal(true)
        end)
    end)
end