--!native
--!optimize 2
--!nonstrict

local IsMap = require(script.Parent.Parent.Shared.IsMap)

return table.freeze({
    Freeze = function(Call)
        return function(Array, Into, New)
            local Result = Call(Array, Into, New)
            return (
                table.isfrozen(Result) and Result or -- Frozen already -> we can return it, no need to freeze.
                table.freeze((Result == Into or Result == Array) and table.clone(Result) or Result) -- Otherwise, freeze the result, or a copy of the result if it was one of the args.
            )
        end
    end;
    Assert = function(Call)
        return function(Into, New)
            assert(type(Into) == "table" and not IsMap(Into), "Arg #1 was not an array")
            assert(type(New) == "table" and not IsMap(New), "Arg #2 was not an array")

            return Call(Into, New)
        end
    end;
})