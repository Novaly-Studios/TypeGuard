--- Puts an array's values through a transformation function, mapping the outputs into a new array - nil values will be skipped & will not leave holes in the new array.
local function Map<T>(Array: {T}, Operator: (T, number) -> T?, Allocate: number?): {T}
    local Result = table.create(Allocate or #Array)
    local Index = 1

    for ItemIndex = 1, #Array do
        local Value = Array[ItemIndex]
        local Transformed = Operator(Value, ItemIndex)

        if (Transformed == nil) then
            -- Skip nil values
            continue
        end

        Result[Index] = Transformed
        Index += 1
    end

    return Result
end

return Map