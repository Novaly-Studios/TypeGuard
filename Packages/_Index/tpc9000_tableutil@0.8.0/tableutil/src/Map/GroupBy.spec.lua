return function()
    local GroupBy = require(script.Parent.Parent).Map.GroupBy

    describe("Map/GroupBy", function()
        it("should group all by a sample value", function()
            local Input = {
                X = {ID = "P"};
                Y = {ID = "Q"};
                Z = {ID = "R"};
            }

            local Result = GroupBy(Input, function(Item)
                return "Group"
            end)

            expect(Result.Group).to.be.ok()
            expect(Result.Group.X.ID).to.equal("P")
            expect(Result.Group.Y.ID).to.equal("Q")
            expect(Result.Group.Z.ID).to.equal("R")
        end)

        it("should group by a category value", function()
            local Input = {
                Item1 = {Category = "X"};
                Item2 = {Category = "Y"};
                Item3 = {Category = "X"};
            }

            local Result = GroupBy(Input, function(Item)
                return Item.Category
            end)

            expect(Result.X).to.be.ok()
            expect(Result.X.Item1.Category).to.equal("X")
            expect(Result.X.Item3.Category).to.equal("X")
            expect(Result.Y).to.be.ok()
            expect(Result.Y.Item2.Category).to.equal("Y")
        end)

        it("should create no output categorization given a nil category", function()
            local Input = {
                Item1 = {Category = "X"};
                Item2 = {Category = nil};
            }

            local Result = GroupBy(Input, function(Item)
                return Item.Category
            end)

            expect(Result.X).to.be.ok()
            expect(next(Result, "X")).never.to.be.ok()
        end)
    end)
end