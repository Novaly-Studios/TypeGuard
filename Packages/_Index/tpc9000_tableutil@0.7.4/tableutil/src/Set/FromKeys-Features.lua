--!native
--!optimize 2
--!nonstrict

return table.freeze({
    Freeze = function(Call)
        return function(ValuesTable)
            return table.freeze(Call(ValuesTable))
        end
    end;
    Assert = function(Call)
        return function(ValuesTable)
            assert(type(ValuesTable) == "table", "Arg #1 was not a table")
            return Call(ValuesTable)
        end
    end;
})