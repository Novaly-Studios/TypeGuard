--!native
--!optimize 2
--!nonstrict

--- Merges various tables together.
--- Metatables are preserved, with new metatables overwrtiting old metatables.
local Merge = require(script.Parent.Merge)
local function MergeMany(...)
    local Count = select("#", ...)
    if (Count == 0) then
        return {}
    end

    local First = (select(1, ...))
    if (Count == 1) then
        return (table.isfrozen(First) and First or table.clone(First))
    end

    local FunctionsMap = ((select(Count, ...)) == true)
    local Result = Merge(First, (select(2, ...)), FunctionsMap)

    for Index = 3, (FunctionsMap and Count - 1 or Count) do
        Result = Merge(Result, (select(Index, ...)), FunctionsMap)
    end

    return Result
end

return MergeMany