--!native
--!optimize 2
--!nonstrict

local IsMap = require(script.Parent.Parent.Shared.IsMap)

return table.freeze({
    Assert = function(Call)
        return function(OrderedArray, Percentile)
            assert(type(OrderedArray) == "table" and not IsMap(OrderedArray), "Arg #1 was not an array")
            assert(type(Percentile) == "number", "Arg #2 was not a number")

            return Call(OrderedArray, Percentile)
        end
    end;
})