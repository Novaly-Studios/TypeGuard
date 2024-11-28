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
        return First
    end

    local Result = Merge(First, (select(2, ...)))
    for Index = 3, Count do
        Result = Merge(Result, (select(Index, ...)))
    end
    return Result
end

return MergeMany