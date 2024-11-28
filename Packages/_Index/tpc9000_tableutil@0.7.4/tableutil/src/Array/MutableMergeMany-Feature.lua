--!native
--!optimize 2
--!nonstrict

local IsMap = require(script.Parent.Parent.Shared.IsMap)

return table.freeze({
    Assert = function(Call)
        return function(...)
            for Index = 1, select("#", ...) do
                local Array = (select(Index, ...))
                assert(type(Array) == "table" and not IsMap(Array), `Arg #{Index} was not an array`)
            end

            return Call(...)
        end
    end;
})