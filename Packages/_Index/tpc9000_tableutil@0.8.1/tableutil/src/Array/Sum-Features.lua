--!native
--!optimize 2
--!nonstrict

local IsMap = require(script.Parent.Parent.Shared.IsMap)

return table.freeze({
    Assert = function(Call)
        return function(Array, From, To)
            local Size = #Array
            From = From or 1
            To = To or Size

            assert(type(Array) == "table" and not IsMap(Array), "Arg #1 was not an array")
            assert(type(From) == "number", "Arg #2 was not a number or nil")
            assert(type(To) == "number", "Arg #3 was not a number or nil")
            assert(From >= 1, "From must be at least 1")
            assert(To <= Size, "To must be less than or equal to the length of the array")

            return Call(Array, From, To)
        end
    end;
})