--!native
--!optimize 2
--!nonstrict

local IsMap = require(script.Parent.Parent.Shared.IsMap)

return table.freeze({
    Assert = function(Call)
        return function(Into, New)
            assert(type(Into) == "table" and not IsMap(Into), "Arg #1 was not an array")
            assert(type(New) == "table" and not IsMap(New), "Arg #2 was not an array")

            return Call(Into, New)
        end
    end;
})