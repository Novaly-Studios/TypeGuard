--!native
--!optimize 2
--!nonstrict

local IsMap = require(script.Parent.Parent.Shared.IsMap)

return table.freeze({
    Freeze = function(Call)
        return function(Array, Start, End)
            return table.freeze(Call(Array, Start, End))
        end
    end;
    Assert = function(Call)
        return function(Array, Start, End)
            assert(type(Array) == "table" and not IsMap(Array), "Arg #1 was not an array")
            assert(type(Start) == "number", "Arg #2 was not a number")
            assert(type(End) == "number", "Arg #3 was not a number")
            return Call(Array, Start, End)
        end
    end;
})