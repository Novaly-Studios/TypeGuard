local function _IsOrdered(Structure: {any}, AscendingOrDescending: boolean?): (boolean)
    -- Check ascending.
    if (AscendingOrDescending) then
        local LastValue = Structure[1]

        for Index = 2, #Structure do
            local Value = Structure[Index]

            if (Value < LastValue) then
                return false
            end

            LastValue = Value
        end

        return true
    end

    -- Check descending.
    local LastValue = Structure[1]

    for Index = 2, #Structure do
        local Value = Structure[Index]

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
local function IsOrdered(Structure: {any}, AscendingOrDescendingOrEither: boolean?): (boolean)
    if (AscendingOrDescendingOrEither == nil and Structure[1] ~= nil and Structure[2] ~= nil) then
        return _IsOrdered(Structure, Structure[1] < Structure[2])
    end

    return _IsOrdered(Structure, AscendingOrDescendingOrEither)
end

return IsOrdered