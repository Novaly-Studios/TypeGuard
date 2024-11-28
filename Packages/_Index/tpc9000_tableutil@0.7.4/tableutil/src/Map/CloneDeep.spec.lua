return function()
    local CloneDeep = require(script.Parent.Parent).Map.CloneDeep
    local Equals = require(script.Parent.Parent).Map.Equals

    describe("Map/CloneDeep", function()
        it("it should copy a blank array into a new blank array", function()
            local Target = {}
            local Copied = CloneDeep(Target)

            expect(next(Copied)).never.to.be.ok()
            expect(Target).never.to.equal(Copied)
        end)

        it("should copy a single element", function()
            local Target = {X = 1}
            local Copied = CloneDeep(Target)

            expect(Target).never.to.equal(Copied)
            expect(Equals(Target, Copied)).to.equal(true)
        end)

        it("should copy a multiple elements", function()
            local Target = {X = 1, Y = 2, Z = 3}
            local Copied = CloneDeep(Target)

            expect(Target).never.to.equal(Copied)
            expect(Equals(Target, Copied)).to.equal(true)
        end)

        it("should copy a nested table", function()
            local Target = {X = 1, Y = {Z = 2, W = {P = "Test"}}}
            local Copied = CloneDeep(Target)

            expect(Target).never.to.equal(Copied)
            expect(Copied.X).to.equal(1)
            expect(Copied.Y).to.be.ok()
            expect(Copied.Y).never.to.equal(Target.Y)
            expect(Copied.Y.Z).to.equal(2)
            expect(Copied.Y.W).to.be.ok()
            expect(Copied.Y.W).never.to.equal(Target.Y.W)
            expect(Copied.Y.W.P).to.equal("Test")
        end)

        it("should preserve metatables", function()
            local MT = {__tostring = function()
                return "Test"
            end}
            local X = {
                Y = {
                    P = 1;
                    Q = 2;
                };
                Z = {
                    R = 3;
                    S = 4;
                    AHHH = setmetatable({}, MT);
                };
            }
            expect(getmetatable(CloneDeep(X).Z.AHHH)).to.equal(MT)
        end)
    end)
end