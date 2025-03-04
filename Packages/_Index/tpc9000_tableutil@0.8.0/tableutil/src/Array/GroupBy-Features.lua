--!native
--!optimize 2
--!nonstrict

local IsMap = require(script.Parent.Parent.Shared.IsMap)

return table.freeze({
    Freeze = function(Call)
        return function(Array, Grouper)
            return table.freeze(Call(Array, Grouper))
        end
    end;
    Assert = function(Call)
        return function(Array, Grouper)
            assert(type(Array) == "table" and not IsMap(Array), "Arg #1 was not an array")
            assert(type(Grouper) == "function", "Arg #2 was not a function")

            return Call(Array, Grouper)
        end
    end;
})