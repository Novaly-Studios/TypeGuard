--!native
--!optimize 2
--!nonstrict

--- Removes a range of elements from an array.
local function RemoveRange<T>(Array: {T}, Start: number, End: number): {T}
    local Range = End - Start + 1
    local Length = #Array

    if (Range == Length) then
        return Array
    end

    local Result = table.create(Length - Range)
    table.move(Array, 1, Start - 1, 1, Result)
    table.move(Array, End + 1, Length, Start, Result)
    return Result
end

return RemoveRange