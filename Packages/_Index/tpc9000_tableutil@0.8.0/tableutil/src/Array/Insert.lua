--!native
--!optimize 2
--!nonstrict

--- Inserts a value into a new array with an optional "insert at" index.
local function Insert<T>(Array: {T}, Value: T?, At: number?): {T}
    local NewSize = #Array + 1
    At = At or NewSize

    if (Value == nil and At == NewSize) then
        return Array
    end

    local Result = table.create(NewSize)

    table.move(Array, 1, At :: number - 1, 1, Result)
    Result[At] = Value
    table.move(Array, At :: number, NewSize - 1, At :: number + 1, Result)

    return Result
end

return Insert