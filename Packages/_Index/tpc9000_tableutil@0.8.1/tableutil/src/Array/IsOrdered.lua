--!native
--!optimize 2
--!nonstrict

local function _IsOrdered(Array: {any}, AscendingOrDescending: boolean?): (boolean)
    -- Check ascending.
    if (AscendingOrDescending) then
        local LastValue = Array[1]

        for Index = 2, #Array do
            local Value = Array[Index]

            if (Value < LastValue) then
                return false
            end

            LastValue = Value
        end

        return true
    end

    -- Check descending.
    local LastValue = Array[1]

    for Index = 2, #Array do
        local Value = Array[Index]

        if (Value > LastValue) then
            return false
        end

        LastValue = Value
    end

    return true
end

--- Returns true if the given array is ordered in the given direction.
--- AscendingOrDescendingOrEither: true -> ascending.
--- AscendingOrDescendingOrEither: false -> descending.
--- AscendingOrDescendingOrEither: nil -> either.
local function IsOrdered(Array: {any}, AscendingOrDescendingOrEither: boolean?): (boolean)
    if (AscendingOrDescendingOrEither == nil and Array[1] ~= nil and Array[2] ~= nil) then
        return _IsOrdered(Array, Array[1] < Array[2])
    end
    return _IsOrdered(Array, AscendingOrDescendingOrEither)
end

return IsOrdered