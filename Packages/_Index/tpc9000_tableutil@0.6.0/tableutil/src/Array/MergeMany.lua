--- Merges multiple arrays together, in order.
local function MergeMany<T>(...: {T}): {T}
    local First = select(1, ...)
    local Result = table.clone(First)
    local Index = #Result + 1

    for SubArrayIndex = 2, select("#", ...) do
        local SubArray = select(SubArrayIndex, ...)

        if (not SubArray) then
            continue
        end

        local Size = #SubArray
        table.move(SubArray, 1, Size, Index, Result)
        Index += Size
    end

    return Result
end

return MergeMany