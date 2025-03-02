--!native
--!optimize 2
--!nonstrict

local IsMap = require(script.Parent.Parent.Shared.IsMap)

return table.freeze({
    Freeze = function(Call)
        return function(Array, Condition)
            local Result = Call(Array, Condition)
            return (
                table.isfrozen(Result) and Result or -- Frozen already -> we can return it, no need to freeze.
                table.freeze(Result == Array and table.clone(Result) or Result) -- Otherwise, freeze the result, or a copy of the result if it was one of the args.
            )
        end
    end;
    Assert = function(Call)
        return function(Array, Condition)
            assert(type(Array) == "table" and not IsMap(Array), "Arg #1 was not an array")
            assert(type(Condition) == "function", "Arg #2 was not a function")

            return Call(Array, Condition)
        end
    end;
})