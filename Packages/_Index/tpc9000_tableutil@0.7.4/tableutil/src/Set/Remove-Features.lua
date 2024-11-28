--!native
--!optimize 2
--!nonstrict

local DetectSet = require(script.Parent._DetectSet)

return table.freeze({
    Freeze = function(Call)
        return function(Set, Value)
            local Result = Call(Set, Value)
            return (table.isfrozen(Result) and Result or table.freeze(Result))
        end
    end;
    Assert = function(Call)
        return function(Set, Value)
            assert(type(Set) == "table" and DetectSet(Set), "Arg #1 is not a set")
            return Call(Set, Value)
        end
    end;
})