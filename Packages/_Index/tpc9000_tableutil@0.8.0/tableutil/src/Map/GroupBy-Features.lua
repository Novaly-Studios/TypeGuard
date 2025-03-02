--!native
--!optimize 2
--!nonstrict

local IsArray = require(script.Parent.Parent.Shared.IsArray)

return table.freeze({
    Freeze = function(Call)
        return function(Structure, Grouper)
            return table.freeze(Call(Structure, Grouper))
        end
    end;
    Assert = function(Call)
        return function(Structure, Grouper)
            assert(type(Structure) == "table" and not IsArray(Structure), "Arg #1 was not a map")
            assert(type(Grouper) == "function", "Arg #2 was not a function")

            return Call(Structure, Grouper)
        end
    end;
})