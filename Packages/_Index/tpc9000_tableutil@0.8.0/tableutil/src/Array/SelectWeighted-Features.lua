--!native
--!optimize 2
--!nonstrict

local IsMap = require(script.Parent.Parent.Shared.IsMap)

return table.freeze({
    Freeze = function(Call)
        return function(Array, WeightKey, Seed, SortMutate)
            local Result = Call(Array, WeightKey, Seed, SortMutate)
            return (table.isfrozen(Result) and Result or table.freeze(table.clone(Result)))
        end
    end;
    Assert = function(Call)
        return function(Array, WeightKey, Seed, SortMutate)
            assert(type(Array) == "table" and not IsMap(Array), "Arg #1 was not an array")
            assert(type(WeightKey) == "string", "Arg #2 was not a string")
            assert(Seed == nil or type(Seed) == "number", "Arg #3 was not a number or nil")
            assert(SortMutate == nil or type(SortMutate) == "boolean", "Arg #4 was not a boolean or nil")

            return Call(Array, WeightKey, Seed, SortMutate)
        end
    end;
})