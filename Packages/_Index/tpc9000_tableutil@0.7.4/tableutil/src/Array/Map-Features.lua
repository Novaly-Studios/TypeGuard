--!native
--!optimize 2
--!nonstrict

local IsMap = require(script.Parent.Parent.Shared.IsMap)

return table.freeze({
    Freeze = function(Call)
        return function(Array, Operator, Allocate)
            return table.freeze(Call(Array, Operator, Allocate))
        end
    end;
    Assert = function(Call)
        return function(Array, Operator, Allocate)
            assert(type(Array) == "table" and not IsMap(Array), "Arg #1 was not an array")
            assert(type(Operator) == "function", "Arg #2 was not a function")
            assert(type(Allocate) == "number" or Allocate == nil, "Arg #3 was not a number or nil")
            return Call(Array, Operator, Allocate)
        end
    end;
})