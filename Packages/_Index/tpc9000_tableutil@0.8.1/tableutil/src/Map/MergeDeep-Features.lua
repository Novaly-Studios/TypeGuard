--!native
--!optimize 2
--!nonstrict

local IsArray = require(script.Parent.Parent.Shared.IsArray)

return table.freeze({
    Init = function(Call, WrappedSelfCall)
        local Wrapped

        return function(X, Y, FunctionsMap)
            Wrapped = Wrapped or WrappedSelfCall()
            return Call(X, Y, FunctionsMap, Wrapped)
        end
    end;
    Freeze = function(Call)
        return function(X, Y, FunctionsMap, Wrapped)
            local Result = Call(X, Y, FunctionsMap, Wrapped)

            return (
                table.isfrozen(Result) and Result or -- Frozen already -> we can return it, no need to freeze.
                table.freeze((Result == X or Result == Y) and table.clone(Result) or Result) -- Otherwise, freeze the result recursively, or a copy of the result if it was one of the args.
            )
        end
    end;
    Assert = function(Call)
        return function(X, Y, FunctionsMap, Wrapped)
            assert(type(X) == "table" and not IsArray(X), "Arg #1 was not a map")
            assert(type(Y) == "table" and not IsArray(Y), "Arg #2 was not a map")
            assert(FunctionsMap == nil or type(FunctionsMap) == "boolean", `Arg #3 was not a boolean`)

            return Call(X, Y, FunctionsMap, Wrapped)
        end
    end;
})