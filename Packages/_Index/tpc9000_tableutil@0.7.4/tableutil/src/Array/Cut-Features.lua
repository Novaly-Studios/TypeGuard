--!native
--!optimize 2
--!nonstrict

local IsMap = require(script.Parent.Parent.Shared.IsMap)

return table.freeze({
    Freeze = function(Call)
        return function(Array, From, To)
            return table.freeze(Call(Array, From, To))
        end
    end;
    Assert = function(Call)
        return function(Array, From, To)
            assert(type(Array) == "table" and not IsMap(Array), "Arg #1 was not an array")
            assert(type(From) == "number", "Arg #2 was not a number")
            assert(type(To) == "number", "Arg #3 was not a number")

            local Size = #Array
            assert(From >= 1, "Start index less than 1!")
            assert(To <= Size, "End index beyond array length!")
            assert(From <= To, "Start index must be less than or equal to end index")
            return Call(Array, From, To)
        end
    end;
})