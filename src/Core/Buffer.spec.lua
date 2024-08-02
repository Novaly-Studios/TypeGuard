local function anyfn(...) return ({} :: any) end
it = it or anyfn
expect = expect or anyfn
describe = describe or anyfn

return function()
    local GetValues = require(script.Parent._TestValues)
    local TypeGuard = require(script.Parent.Parent)
    local Base = TypeGuard.Buffer()

    describe("Init", function()
        it("should reject non-buffer values", function()
            for _, Value in GetValues("Buffer") do
                expect(Base:Check(Value)).to.equal(false)
            end
        end)

        it("should accept buffer values", function()
            expect(Base:Check(buffer.create(1))).to.equal(true)
        end)
    end)

    describe("Serialize, Deserialize", function()
        local RNG = Random.new(8745789347)
        local function Fill(Target: buffer)
            for Index = 0, buffer.len(Target) - 1 do
                buffer.writeu8(Target, Index, RNG:NextInteger(0, 255))
            end
        end

        it("should serialize a buffer with the correct size", function()
            local Buffer = buffer.create(8)
            Fill(Buffer)
            local Test = Base:Serialize(Buffer)
            expect(#buffer.tostring(Test)).to.equal(12) -- 4 bytes for size + 8 bytes for the buffer
        end)

        it("should deserialize a buffer with the correct size", function()
            local Buffer = buffer.create(8)
            Fill(Buffer)
            local Test = Base:Serialize(Buffer)
            local Deserialized = Base:Deserialize(Test)
            expect(buffer.tostring(Deserialized)).to.equal(buffer.tostring(Buffer))
        end)
    end)
end