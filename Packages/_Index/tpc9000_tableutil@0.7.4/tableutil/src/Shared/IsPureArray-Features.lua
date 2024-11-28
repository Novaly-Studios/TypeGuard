--!native
--!optimize 2
--!nonstrict

return table.freeze({
    Assert = function(Call)
        return function(Structure)
            assert(type(Structure) == "table", "Arg #1 was not a table")
            return Call(Structure)
        end
    end;
})