--!native
--!optimize 2
--!nonstrict

local IsArray = require(script.Parent.Parent.Shared.IsArray)

return table.freeze({
    Freeze = function(Call)
        return function(Structure, Operator)
            return table.freeze(Call(Structure, Operator))
        end
    end;
    Assert = function(Call)
        return function(Structure, Operator)
            assert(type(Structure) == "table" and not IsArray(Structure), "Arg #1 was not a map")
            assert(type(Operator) == "function", "Arg #2 was not a function")
            return Call(Structure, Operator)
        end
    end;
})