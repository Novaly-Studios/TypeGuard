--!native
--!optimize 2
--!nonstrict

local MutableMerge = require(script.Parent.MutableMerge)

--- Merges various tables together.
--- Metatables are preserved, with new metatables overwrtiting old metatables.
local function MutableMergeMany(...: {any}): {any}
    local Count = select("#", ...)
    local Target = (select(1, ...))
    local FunctionsMap = ((select(Count, ...)) == true)

    for Index = 2, (FunctionsMap and Count - 1 or Count) do
        local Table = (select(Index, ...))

        if (not Table) then
            continue
        end

        MutableMerge(Target, Table, FunctionsMap)
    end

    return Target
end

return MutableMergeMany