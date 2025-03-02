--!native
--!optimize 2
--!nonstrict

--- Removes a single element from an array.
local function Remove<T>(Array: {T}, Index: number?): {T}
    local ArrayLength = #Array
    if (ArrayLength == 0) then
        return Array
    end

    local Result = table.create(math.max(ArrayLength - 1, 0))
    Index = Index or ArrayLength
    table.move(Array, 1, Index :: number - 1, 1, Result)
    table.move(Array, Index :: number + 1, ArrayLength, Index :: number, Result)
    return Result
end

return Remove