--!native
--!optimize 2
--!nonstrict

local IsMap = require(script.Parent.Parent.Shared.IsMap)

return table.freeze({
    Freeze = function(Call)
        return function(Array, Value, At)
            local Result = Call(Array, Value, At)
            return (
                table.isfrozen(Result) and Result or -- Frozen already -> we can return it, no need to freeze.
                table.freeze(Result == Array and table.clone(Result) or Result) -- Otherwise, freeze the result, or a copy of the result if it was one of the args.
            )
        end
    end;
    Assert = function(Call)
        return function(Array, Value, At)
            local NewSize = #Array + 1
            At = At or NewSize

            assert(type(Array) == "table" and not IsMap(Array), "Arg #1 was not an array")
            assert(type(At) == "number", "Arg #3 was not a number")
            assert(At >= 1 and At <= NewSize, "Insert index out of array range")

            return Call(Array, Value, At)
        end
    end;
})