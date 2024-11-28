--!native
--!optimize 2
--!nonstrict

local IsArray = require(script.Parent.Parent.Shared.IsArray)

return table.freeze({
    Assert = function(Call)
        return function(...)
            for Index = 1, select("#", ...) do
                local Array = (select(Index, ...))
                assert(type(Array) == "table" and not IsArray(Array), `Arg #{Index} was not a map`)
            end

            return Call(...)
        end
    end;
})