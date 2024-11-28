--!native
--!optimize 2
--!nonstrict

--- Cuts a chunk from an array given a starting and ending index - the difference in these indexes can be negative - faster if positive e.g. Cut(X, 1, 4) over Cut(X, 4, 1)
local function Cut<T>(Array: {T}, From: number, To: number): {T}
    local Diff = To - From
    local Range = math.abs(Diff)

    if (Range == #Array - 1) then
        return Array
    end

    return table.move(Array, From, To, 1, table.create(Range))
end

return Cut