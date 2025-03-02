--!native
--!optimize 2
--!nonstrict

local DetectSet = require(script.Parent._DetectSet)

return table.freeze({
    Freeze = function(Call)
        return function(Set1, Set2)
            local Result = Call(Set1, Set2)
            return (
                table.isfrozen(Result) and Result or -- Frozen already -> we can return it, no need to freeze.
                table.freeze((Result == Set1 or Result == Set2) and table.clone(Result) or Result) -- Otherwise, freeze the result, or a copy of the result if it was one of the args.
            )
        end
    end;
    Assert = function(Call)
        return function(Set1, Set2)
            assert(type(Set1) == "table" and DetectSet(Set1), "Arg #1 was not a set")
            assert(type(Set2) == "table" and DetectSet(Set2), "Arg #2 was not a set")

            return Call(Set1, Set2)
        end
    end;
})