--- Binary search on an ordered array.
local function BinarySearch<T>(Array: {T}, Target: T, ReturnClosestIndex: boolean?): number?
    local Min = 1
    local Max = #Array
    local Middle = math.floor((Min + Max) / 2)

    while (Min <= Max) do
        local Value = Array[Middle]

        if (Value == Target) then
            return Middle
        elseif (Value < Target) then
            Min = Middle + 1
        else
            Max = Middle - 1
        end

        Middle = math.floor((Min + Max) / 2)
    end

    return (ReturnClosestIndex and Middle or nil)
end

return BinarySearch