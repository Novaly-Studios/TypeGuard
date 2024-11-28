--!native
--!optimize 2
--!nonstrict

local IsMap = require(script.Parent.Parent.Shared.IsMap)

return table.freeze({
    Freeze = function(Call)
        return function(Array)
            return table.freeze(Call(Array))
        end
    end;
    Assert = function(Call)
        return function(Array)
            assert(type(Array) == "table" and not IsMap(Array), "Arg #1 was not an array")
            return Call(Array)
        end
    end;
})