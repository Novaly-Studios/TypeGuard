--!native
--!optimize 2
--!nonstrict

--- Reduces an array to a single value from its left-most value to its right-most value.
local function FoldLeft<T>(Array: {T}, Processor: (T, T, number, number) -> T, Initial: T?): T?
    local Aggregate = Initial
    local Size = #Array

    for Index, Value in Array do
        Aggregate = Processor(Aggregate, Value, Index, Size)
    end

    return Aggregate
end

return FoldLeft