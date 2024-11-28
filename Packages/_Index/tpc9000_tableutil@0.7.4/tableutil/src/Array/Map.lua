--!native
--!optimize 2
--!nonstrict

--- Puts an array's values through a transformation function, mapping the outputs into a new array - nil values will be skipped & will not leave holes in the new array.
local function Map<T>(Array: {T}, Operator: ((T, number) -> (T?)), Allocate: number?): {T}
    local Result = table.create(Allocate or #Array)
    local Equals = true
    local Index = 1

    for ItemIndex = 1, #Array do
        local Transformed = Operator(Array[ItemIndex], ItemIndex)

        -- Skip nil values.
        if (Transformed == nil) then
            continue
        end

        Result[Index] = Transformed
        if (Array[Index] ~= Transformed) then
            Equals = false
        end
        Index += 1
    end

    return (Equals and Array or Result)
end

return Map