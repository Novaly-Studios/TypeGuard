return function()
    local Shuffle = require(script.Parent.Parent).Array.Shuffle

    describe("Array/Shuffle", function()
        it("should return an empty array given an empty array", function()
            local Result = Shuffle({})
            expect(next(Result)).never.to.be.ok()
        end)

        it("should return a one-item array given a one-item array", function()
            local Result = Shuffle({1})
            expect(Result[1]).to.equal(1)
        end)

        it("should shuffle items given a seed", function()
            local Original = {1, 2, 3, 4, 5, 6, 7, 8, 9, 10}

            -- Two tests to ensure seed is locally deterministic
            local Result1 = Shuffle(Original, 100)
            local Result2 = Shuffle(Original, 100)

            local Sum0 = 0
            local Sum1 = 0
            local Sum2 = 0

            local Different1 = false
            local Different2 = false

            for Index = 1, #Result1 do
                Sum0 += Original[Index]
                Sum1 += Result1[Index]
                Sum2 += Result2[Index]

                Different1 = Different1 or Result1[Index] ~= Original[Index]
                Different2 = Different2 or Result2[Index] ~= Original[Index]
                expect(Result1[Index]).to.equal(Result2[Index])
            end

            expect(Sum0).to.equal(Sum1)
            expect(Sum1).to.equal(Sum2)
            expect(Different1).to.equal(true)
            expect(Different2).to.equal(true)
        end)
    end)
end