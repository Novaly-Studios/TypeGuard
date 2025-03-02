--!native
--!optimize 2
--!nonstrict

local IsArray = require(script.Parent.Parent.Shared.IsArray)

return table.freeze({
    Freeze = function(Call)
        return function(X, Y)
            local Result = Call(X, Y)
            return (
                table.isfrozen(Result) and Result or -- Frozen already -> we can return it, no need to freeze.
                table.freeze(Result == Y and table.clone(Result) or Result) -- Otherwise, freeze the result, or a copy of the result if it was one of the args.
            )
        end
    end;
    Assert = function(Call)
        return function(X, Y)
            assert(type(X) == "table" and not IsArray(X), "Arg #1 was not a map")
            assert(type(Y) == "table" and not IsArray(Y), "Arg #2 was not a map")

            return Call(X, Y)
        end
    end;
})