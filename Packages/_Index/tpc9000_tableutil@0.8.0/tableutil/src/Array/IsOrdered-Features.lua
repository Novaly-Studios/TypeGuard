--!native
--!optimize 2
--!nonstrict

local IsMap = require(script.Parent.Parent.Shared.IsMap)

return table.freeze({
    Assert = function(Call)
        return function(Array, AscendingOrDescendingOrEither)
            assert(type(Array) == "table" and not IsMap(Array), "Arg #1 was not an array")
            assert(type(AscendingOrDescendingOrEither) == "boolean" or AscendingOrDescendingOrEither == nil, "Arg #2 was not a boolean or nil")

            return Call(Array, AscendingOrDescendingOrEither)
        end
    end;
})