--!native
--!optimize 2
--!nonstrict

local IsMap = require(script.Parent.Parent.Shared.IsMap)

return table.freeze({
    Freeze = function(Call)
        return function(Array, Dimension)
            local Result = table.freeze(Call(Array, Dimension))
            for _, Combination in Result do
                table.freeze(Combination)
            end
            return Result
        end
    end;
    Assert = function(Call)
        return function(Array, Dimension)
            assert(type(Array) == "table" and not IsMap(Array), "Arg #1 was not an array")
            assert(type(Dimension) == "number", "Arg #2 was not a number")
            return Call(Array, Dimension)
        end
    end;
})