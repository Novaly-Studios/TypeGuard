local function anyfn(...) return ({} :: any) end
it = it or anyfn
expect = expect or anyfn
describe = describe or anyfn

return function()
    local GetValues = require(script.Parent.Parent.Core._TestValues)
    local TypeGuard = require(script.Parent.Parent)
    local Base = TypeGuard.PathWaypoint()

    describe("Init", function()
        it("should reject non-PathWaypoints", function()
            for _, Value in GetValues("PathWaypoint") do
                expect(Base:Check(Value)).to.equal(false)
            end
        end)

        it("should accept PathWaypoints", function()
            expect(Base:Check(PathWaypoint.new(Vector3.one, Enum.PathWaypointAction.Walk))).to.equal(true)
        end)
    end)

    describe("Serialize, Deserialize", function()
        it("should correctly serialize & deserialize PathWaypoints", function()
            local Test = PathWaypoint.new(Vector3.one, Enum.PathWaypointAction.Walk, "Test")
            expect(Base:Deserialize(Base:Serialize(Test))).to.equal(Test)
        end)
    end)
end