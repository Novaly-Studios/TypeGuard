--!native
--!optimize 2
--!nonstrict

local IsMap = require(script.Parent.Parent.Shared.IsMap)

return table.freeze({
    Freeze = function(Call)
        return function(Array, Index)
            local Result = Call(Array, Index)
            return (
                table.isfrozen(Result) and Result or -- Frozen already -> we can return it, no need to freeze.
                table.freeze(Result == Array and table.clone(Result) or Result) -- Otherwise, freeze the result, or a copy of the result if it was one of the args.
            )
        end
    end;
    Assert = function(Call)
        return function(Array, Index)
            local Size = #Array
            Index = Index or Size
            assert(type(Array) == "table" and not IsMap(Array), "Arg #1 was not an array")
            assert(type(Index) == "number", "Arg #2 was not a number")
            assert(Index >= 0, "Index must be positive")
            assert(Index <= Size + 1, "Index out of bounds")
            return Call(Array, Index)
        end
    end;
})