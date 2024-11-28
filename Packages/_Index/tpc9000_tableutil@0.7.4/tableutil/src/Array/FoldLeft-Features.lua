--!native
--!optimize 2
--!nonstrict

local IsMap = require(script.Parent.Parent.Shared.IsMap)

return table.freeze({
    Freeze = function(Call)
        return function(Array, Processor, Initial)
            local Result = Call(Array, Processor, Initial)
            return (type(Result) == "table" and table.freeze(Result) or Result)
        end
    end;
    Assert = function(Call)
        return function(Array, Processor, Initial)
            assert(type(Array) == "table" and not IsMap(Array), "Arg #1 was not an array")
            assert(type(Processor) == "function", "Arg #2 was not a function")
            return Call(Array, Processor, Initial)
        end
    end;
})