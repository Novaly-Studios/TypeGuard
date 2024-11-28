--!native
--!optimize 2
--!nonstrict

--- Reduces an array to a single value from its right-most value to its left-most value.
local function FoldRight<T>(Array: {T}, Processor: (T, T, number, number) -> T, Initial: T): T
    local Aggregate = Initial
    local Size = #Array

    for Index = Size, 1, -1 do
        Aggregate = Processor(Aggregate, Array[Index], Index, Size)
    end

    return Aggregate
end

return FoldRight