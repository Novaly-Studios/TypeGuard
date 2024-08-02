--- Flips all items in an array.
local function MutableReverse<T>(Array: {T})
    local ArraySize = #Array

    for Index = 1, math.floor(ArraySize / 2) do
        local Other = ArraySize - Index + 1
        Array[Index], Array[Other] = Array[Other], Array[Index]
    end
end

return MutableReverse