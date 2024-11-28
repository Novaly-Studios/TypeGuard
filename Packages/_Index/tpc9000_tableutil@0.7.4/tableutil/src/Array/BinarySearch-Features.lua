--!native
--!optimize 2
--!nonstrict

local IsMap = require(script.Parent.Parent.Shared.IsMap)

return table.freeze({
    Assert = function(Call)
        return function(Array, Target, ReturnClosestIndex)
            assert(type(Array) == "table" and not IsMap(Array), "Arg #1 was not an array")
            assert(Target ~= nil, "Arg #2 was nil")
            assert(ReturnClosestIndex == nil or type(ReturnClosestIndex) == "boolean", "Arg #3 was not a boolean or nil")
            return Call(Array, Target, ReturnClosestIndex)
        end
    end;
})