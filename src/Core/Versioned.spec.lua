local function anyfn(...) return ({} :: any) end
it = it or anyfn
expect = expect or anyfn
describe = describe or anyfn

return function()
    local DeepEquals = require(script.Parent._Equals)
    local TypeGuard = require(script.Parent.Parent)
    local Number = TypeGuard.Number()

    describe("DefineVersions", function()
        it("should deserialize and reserialize the same value with a newer version", function()
            local Object1 = TypeGuard.Object({
                X = Number;
                Y = Number;
            }):Strict()
            local Object2 = TypeGuard.Object({
                X = Number:Integer(8, true);
                Y = Number:Integer(8, true);
            }):Strict()
            local Test1 = TypeGuard.Versioned({
                [1] = Object1;
            })
            local Test2 = TypeGuard.Versioned({
                [1] = Object1;
                [2] = Object2;
            })
        
            local S1 = Test1:Serialize({X = 1, Y = 2})
            local DS1 = Test2:Deserialize(S1)
            local S2 = Test2:Serialize(DS1)
            local DS2 = Test2:Deserialize(S2)
            expect(buffer.len(S1) > buffer.len(S2)).to.equal(true)
            expect(DeepEquals(DS1, DS2)).to.equal(true)
        end)
    end)
end