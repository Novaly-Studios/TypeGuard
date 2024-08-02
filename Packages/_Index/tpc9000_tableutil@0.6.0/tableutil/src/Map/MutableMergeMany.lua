local MutableMerge = require(script.Parent:WaitForChild("MutableMerge"))

--- Merges various tables together.
local function MutableMergeMany(...: {any}): {any}
    local Target = select(1, ...)

    for Index = 2, select("#", ...) do
        local Table = select(Index, ...)

        if (not Table) then
            continue
        end

        MutableMerge(Target, Table)
    end

    return Target
end

return MutableMergeMany