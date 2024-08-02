--- Counts the number of elements in a flat table.
local function Count(Structure: {[any]: any}): number
    local Result = 0

    for _ in Structure do
        Result += 1
    end

    return Result
end

return Count