local function anyfn(...) return ({} :: any) end
it = it or anyfn
expect = expect or anyfn
describe = describe or anyfn

return function()
    local GetValues = require(script.Parent.Parent.Core._TestValues)
    local TypeGuard = require(script.Parent.Parent)
    local Base = TypeGuard.RBXScriptConnection()

    describe("Init", function()
        it("should reject non-RBXScriptConnections", function()
            for _, Value in GetValues("RBXScriptConnection") do
                expect(Base:Check(Value)).to.equal(false)
            end
        end)

        it("should accept RBXScriptConnection", function()
            local Temp = workspace.ChildAdded:Connect(function() end)
            expect(Base:Check(Temp)).to.equal(true)
            Temp:Disconnect()
        end)
    end)
end