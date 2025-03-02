--!native
--!optimize 2
--!nonstrict

local IsMap = require(script.Parent.Parent.Shared.IsMap)

return table.freeze({
    Assert = function(Call)
        return function(X, Y)
            assert(type(X) == "table" and not IsMap(X), "Arg #1 was not an array")
            assert(type(Y) == "table" and not IsMap(Y), "Arg #2 was not an array")

            return Call(X, Y)
        end
    end;
})