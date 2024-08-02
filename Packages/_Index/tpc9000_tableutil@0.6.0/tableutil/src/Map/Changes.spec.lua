return function()
    local Changes = require(script.Parent.Changes)

    describe("Map/Changes", function()
        it("it should give no changes for two empty tables", function()
            expect(next(Changes({}, {}))).to.equal(nil)
        end)

        it("should give no changes for a created value", function()
            expect(next(Changes({}, {A = 1}))).to.equal(nil)
        end)

        it("should give no changes for a removed value", function()
            expect(next(Changes({A = 1}, {}))).to.equal(nil)
        end)

        it("should give no changes for an equal value", function()
            expect(next(Changes({A = 1}, {A = 1}))).to.equal(nil)
        end)

        it("should give changes for a changed value", function()
            local Changes = Changes({A = 1}, {A = 2})
            expect(Changes.A).to.be.ok()
            expect(Changes.A).to.equal(2)
        end)

        it("should give changes for multiple changed values", function()
            local Changes = Changes({A = 1, B = 2}, {A = 2, B = 3})
            expect(Changes.A).to.equal(2)
            expect(Changes.B).to.equal(3)
        end)
    end)
end