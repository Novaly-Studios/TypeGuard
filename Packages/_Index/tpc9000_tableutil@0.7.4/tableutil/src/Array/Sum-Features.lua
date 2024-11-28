--!native
--!optimize 2
--!nonstrict

local IsMap = require(script.Parent.Parent.Shared.IsMap)

return table.freeze({
    Assert = function(Call)
        return function(Array, From, To)
            assert(type(Array) == "table" and not IsMap(Array), "Arg #1 was not an array")
            assert(From == nil or type(From) == "number", "Arg #2 was not a number or nil")
            assert(To == nil or type(To) == "number", "Arg #3 was not a number or nil")
            return Call(Array, From, To)
        end
    end;
})