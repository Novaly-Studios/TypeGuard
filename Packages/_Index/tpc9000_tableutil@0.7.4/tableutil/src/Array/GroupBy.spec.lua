return function()
    local GroupBy = require(script.Parent.Parent).Array.GroupBy

    describe("Array/GroupBy", function()
        it("should return an empty array from an empty array", function()
            local Result = GroupBy({}, function() end)
            expect(Result).to.be.ok()
            expect(#Result).to.equal(0)
        end)

        it("should correctly group by 1 category with 1 item", function()
            local Input = {
                {Category = "X", Value = 1};
            }

            local Result = GroupBy(Input, function(Item)
                return Item.Category
            end)

            expect(Result).to.be.ok()
            expect(Result.X).to.be.ok()
            expect(#Result.X).to.equal(1)
            expect(Result.X[1]).to.equal(Input[1])
        end)

        it("should correctly group by 1 category with 2 items", function()
            local Input = {
                {Category = "X", Value = 1};
                {Category = "X", Value = 2};
            }

            local Result = GroupBy(Input, function(Item)
                return Item.Category
            end)

            expect(Result).to.be.ok()
            expect(Result.X).to.be.ok()
            expect(#Result.X).to.equal(2)
            expect(Result.X[1]).to.equal(Input[1])
            expect(Result.X[2]).to.equal(Input[2])
        end)

        it("should correctly group by 2 categories with 4 items", function()
            local Input = {
                {Category = "X", Value = 1};
                {Category = "X", Value = 2};
                {Category = "Y", Value = 3};
                {Category = "Y", Value = 4};
            }

            local Result = GroupBy(Input, function(Item)
                return Item.Category
            end)

            expect(Result).to.be.ok()
            expect(Result.X).to.be.ok()
            expect(#Result.X).to.equal(2)
            expect(Result.X[1]).to.equal(Input[1])
            expect(Result.X[2]).to.equal(Input[2])
            expect(Result.Y).to.be.ok()
            expect(#Result.Y).to.equal(2)
            expect(Result.Y[1]).to.equal(Input[3])
            expect(Result.Y[2]).to.equal(Input[4])
        end)

        it("should create no output categorization given a nil category", function()
            local Input = {
                {Category = "X", Value = 1};
                {Category = nil, Value = 2};
            }

            local Result = GroupBy(Input, function(Item)
                return Item.Category
            end)

            expect(Result).to.be.ok()
            expect(Result.X).to.be.ok()
            expect(next(Result, "X")).never.to.be.ok()
        end)
    end)
end