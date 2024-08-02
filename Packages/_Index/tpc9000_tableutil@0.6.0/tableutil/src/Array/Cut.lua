--- Cuts a chunk from an array given a starting and ending index - the difference in these indexes can be negative - faster if positive e.g. Cut(X, 1, 4) over Cut(X, 4, 1)
local function Cut<T>(Array: {T}, From: number, To: number): {T}
    local Size = #Array

    assert(From >= 1, "Start index less than 1!")
    assert(To >= 1, "End index greater than 1!")

    assert(From <= Size, "Start index beyond array length!")
    assert(To <= Size, "End index beyond array length!")

    local Diff = To - From
    local Range = math.abs(Diff)

    if (Range == Size - 1) then
        return Array
    end

    if (Diff > 0) then
        -- Faster, but table.move doesn't support iterating backwards over a range
        return table.move(Array, From, To, 1, {})
    end

    local Result = table.create(Range)
    local ResultIndex = 1

    for Index = From, To, -1 do
        Result[ResultIndex] = Array[Index]
        ResultIndex += 1
    end

    return Result
end

return Cut