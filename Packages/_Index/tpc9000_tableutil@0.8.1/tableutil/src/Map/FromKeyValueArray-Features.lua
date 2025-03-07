--!native
--!optimize 2
--!nonstrict

local IsMap = require(script.Parent.Parent.Shared.IsMap)

return table.freeze({
    Freeze = function(Call)
        return function(Structure, DepthLimit)
            return table.freeze(Call(Structure, DepthLimit))
        end
    end;
    Assert = function(Call)
        return function(Structure)
            assert(type(Structure) == "table" and not IsMap(Structure), "Arg #1 was not an array")

            return Call(Structure)
        end
    end;
})