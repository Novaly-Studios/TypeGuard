--!native
--!optimize 2
--!nonstrict

local DetectSet = require(script.Parent._DetectSet)

return table.freeze({
    Freeze = function(Call)
        return function(Set)
            return table.freeze(Call(Set))
        end
    end;
    Assert = function(Call)
        return function(Set)
            assert(type(Set) == "table" and DetectSet(Set), "Arg #1 is not a set")
            return Call(Set)
        end
    end;
})