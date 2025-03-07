--!native
--!optimize 2
--!nonstrict

local IsArray = require(script.Parent.Parent.Shared.IsArray)

return table.freeze({
    Assert = function(Call)
        return function(Map, Seed)
            assert(type(Map) == "table" and not IsArray(Map), "Arg #1 was not a map")
            assert(Seed == nil or type(Seed) == "number", "Arg #2 was not a number")

            return Call(Map, Seed)
        end
    end;
})