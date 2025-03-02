--!native
--!optimize 2
--!nonstrict

local IsArray = require(script.Parent.Parent.Shared.IsArray)

return table.freeze({
    Assert = function(Call)
        return function(...)
            local Count = select("#", ...)
            for Index = 1, Count - 1 do
                local Map = (select(Index, ...))
                assert(type(Map) == "table" and not IsArray(Map), `Arg #{Index} was not a map`)
            end

            local Last = (select(Count, ...))
            assert((type(Last) == "table" and not IsArray(Last)) or type(Last) == "boolean", `Arg #{Count} was not a map or boolean`)

            return Call(...)
        end
    end;
})