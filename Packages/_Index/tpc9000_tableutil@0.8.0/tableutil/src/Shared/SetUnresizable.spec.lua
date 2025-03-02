return function()
    local SetUnresizable = require(script.Parent.SetUnresizable)

    describe("Shared/SetUnresizable", function()
        it("should throw an error when attempting to write to non-existing keys", function()
            local Subject = {X = 123}
            SetUnresizable(Subject)

            expect(function()
                Subject.A = 1
            end).to.throw()
        end)

        it("should not throw an error when attempting to write to existing keys", function()
            local Subject = {A = 1}
            SetUnresizable(Subject)

            expect(function()
                Subject.A = 2
            end).never.to.throw()
        end)
    end)
end