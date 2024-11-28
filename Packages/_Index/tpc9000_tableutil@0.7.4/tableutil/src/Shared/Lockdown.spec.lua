return function()
    local Lockdown = require(script.Parent.Lockdown)

    describe("Shared/Lockdown", function()
        it("should throw an error when attempting to index existing keys", function()
            local Subject = {X = 123}
            Lockdown(Subject)

            expect(function()
                local _ = Subject.X
            end).to.throw()
        end)

        it("should throw an error when attempting to index existing non-existing keys", function()
            local Subject = {X = 123}
            Lockdown(Subject)

            expect(function()
                local _ = Subject.Y
            end).to.throw()
        end)

        it("should throw an error when attempting to write to existing keys", function()
            local Subject = {A = 1}
            Lockdown(Subject)

            expect(function()
                Subject.A = 2
            end).to.throw()
        end)

        it("should throw an error when attempting to write to non-existing keys", function()
            local Subject = {X = 123}
            Lockdown(Subject)

            expect(function()
                Subject.A = 1
            end).to.throw()
        end)
    end)
end