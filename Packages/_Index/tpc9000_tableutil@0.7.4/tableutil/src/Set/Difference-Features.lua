--!native
--!optimize 2
--!nonstrict

local DetectSet = require(script.Parent._DetectSet)

return table.freeze({
    Freeze = function(Call)
        return function(Set1, Set2)
            return table.freeze(Call(Set1, Set2))
        end
    end;
    Assert = function(Call)
        return function(Set1, Set2)
            assert(type(Set1) == "table" and DetectSet(Set1), "Arg #1 is not a set")
            assert(type(Set2) == "table" and DetectSet(Set2), "Arg #2 is not a set")
            return Call(Set1, Set2)
        end
    end;
})