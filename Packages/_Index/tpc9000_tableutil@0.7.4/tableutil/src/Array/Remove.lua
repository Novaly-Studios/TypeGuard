--!native
--!optimize 2
--!nonstrict

--- Removes a single element from an array.
local function Remove<T>(Array: {T}, Index: number?): {T}
    local ArrayLength = #Array
    if (ArrayLength == 0) then
        return Array
    end

    Index = Index or ArrayLength
    assert(Index > 0, "Index must be greater than 0")
    assert(Index <= ArrayLength, "Index out of bounds")

    local Result = table.create(ArrayLength - 1)
    table.move(Array, 1, Index :: number - 1, 1, Result)
    table.move(Array, Index :: number + 1, ArrayLength, Index :: number, Result)
    return Result
end

return Remove