--!native
--!optimize 2
--!nonstrict

local IsMap = require(script.Parent.Parent.Shared.IsMap)

return table.freeze({
    Freeze = function(Call)
        return function(Array, Value, At)
            return table.freeze(Call(Array, Value, At))
        end
    end;
    Assert = function(Call)
        return function(Array, Value, At)
            assert(type(Array) == "table" and not IsMap(Array), "Arg #1 was not an array")
            if (At) then
                assert(type(At) == "number", "Arg #3 was not a number")
            end
            return Call(Array, Value, At)
        end
    end;
})