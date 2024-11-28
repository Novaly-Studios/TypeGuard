--!native
--!optimize 2
--!nonstrict

local IsMap = require(script.Parent.Parent.Shared.IsMap)

return table.freeze({
    Assert = function(Call)
        return function(Array, Seed)
            assert(type(Array) == "table" and not IsMap(Array), "Arg #1 was not an array")
            assert(Seed == nil or type(Seed) == "number", "Arg #2 was not a number or nil")
            return Call(Array, Seed)
        end
    end;
})