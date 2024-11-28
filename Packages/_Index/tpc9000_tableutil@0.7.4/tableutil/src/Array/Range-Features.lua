--!native
--!optimize 2
--!nonstrict

return table.freeze({
    Freeze = function(Call)
        return function(Min, Max)
            return table.freeze(Call(Min, Max))
        end
    end;
    Assert = function(Call)
        return function(Min, Max)            
            assert(type(Min) == "number", "Arg #1 was not a number")
            assert(type(Max) == "number", "Arg #2 was not a number")
            return Call(Min, Max)
        end
    end;
})