--- Merges the second given array into the first.
local function MutableMergeMany(Into: {any}, ...: {any})
    for Index = 1, select("#", ...) do
        local New = select(Index, ...)
        table.move(New, 1, #New, #Into + 1, Into)
    end
end

return MutableMergeMany