return function()
    local Removals = require(script.Parent.Removals)

    describe("Map/Removals", function()
        it("it should give no removals for two empty tables", function()
            expect(next(Removals({}, {}))).to.equal(nil)
        end)

        it("should give no removals for a created value", function()
            expect(next(Removals({}, {A = 1}))).to.equal(nil)
        end)

        it("should give a removal for a removed value", function()
            local Removals = Removals({A = 1}, {})
            expect(Removals.A).to.be.ok()
            expect(Removals.A).to.equal(1)
        end)

        it("should give no removals for an equal value", function()
            expect(next(Removals({A = 1}, {A = 1}))).to.equal(nil)
        end)

        it("should give no removals for a changed value", function()
            expect(next(Removals({A = 1}, {A = 2}))).to.equal(nil)
        end)

        it("should give removals for multiple removed values", function()
            local Removals = Removals({A = 1, B = 2}, {})

            expect(Removals.A).to.be.ok()
            expect(Removals.A).to.equal(1)

            expect(Removals.B).to.be.ok()
            expect(Removals.B).to.equal(2)
        end)

        it("should correctly identify false values", function()
            local Removals = Removals({A = false}, {})

            expect(Removals.A).to.be.ok()
            expect(Removals.A).to.equal(false)
        end)
    end)
end