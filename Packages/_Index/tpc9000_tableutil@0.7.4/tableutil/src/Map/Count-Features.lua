--!native
--!optimize 2
--!nonstrict

local IsArray = require(script.Parent.Parent.Shared.IsArray)

return table.freeze({
    Assert = function(Call)
        return function(Structure)
            assert(type(Structure) == "table" and not IsArray(Structure), "Arg #1 was not a map")
            return Call(Structure)
        end
    end;
})