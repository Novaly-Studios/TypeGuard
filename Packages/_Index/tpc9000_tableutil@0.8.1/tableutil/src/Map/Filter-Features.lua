--!native
--!optimize 2
--!nonstrict

local IsArray = require(script.Parent.Parent.Shared.IsArray)

return table.freeze({
    Protect = function(Call)
        return function(Structure, Predicate)
            local Result = Call(Structure, Predicate)
            return (
                table.isfrozen(Result) and Result or -- Frozen already -> we can return it, no need to freeze.
                table.freeze(Result == Structure and table.clone(Result) or Result) -- Otherwise, freeze the result, or a copy of the result if it was one of the args.
            )
        end
    end;
    Assert = function(Call)
        return function(Structure, Predicate)
            assert(type(Structure) == "table" and not IsArray(Structure), "Arg #1 was not a map")
            assert(type(Predicate) == "function", "Arg #2 was not a function")

            return Call(Structure, Predicate)
        end
    end;
})