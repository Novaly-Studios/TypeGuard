--!native
--!optimize 2
--!nonstrict

local IsArray = require(script.Parent.Parent.Shared.IsArray)

return table.freeze({
    Assert = function(Call)
        return function(X, Y)
            assert(type(X) == "table" and not IsArray(X), `Arg #1 was not a map`)
            assert(type(Y) == "table" and not IsArray(Y), `Arg #2 was not a map`)
            return Call(X, Y)
        end
    end;
})