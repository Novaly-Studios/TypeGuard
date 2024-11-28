--!native
--!optimize 2
--!nonstrict

return table.freeze({
    Freeze = function(Call)
        return function(Structure)
            return table.freeze(Call(Structure))
        end
    end;
    Assert = function(Call)
        return function(Structure)
            assert(type(Structure) == "table", "Arg #1 was not a table")
            return Call(Structure)
        end
    end;
})