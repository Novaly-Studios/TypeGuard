local function anyfn(...) return ({} :: any) end
it = it or anyfn
expect = expect or anyfn
describe = describe or anyfn

return function()
    local GetValues = require(script.Parent.Parent.Core._TestValues)
    local TypeGuard = require(script.Parent.Parent)
    local Base = TypeGuard.RBXScriptSignal()

    describe("Init", function()
        it("should reject non-RBXScriptSignals", function()
            for _, Value in GetValues("RBXScriptSignal") do
                expect(Base:Check(Value)).to.equal(false)
            end
        end)

        it("should accept RBXScriptSignal", function()
            expect(Base:Check(workspace.ChildAdded)).to.equal(true)
        end)
    end)
end