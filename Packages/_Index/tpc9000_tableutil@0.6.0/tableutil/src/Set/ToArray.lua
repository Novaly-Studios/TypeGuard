--!nonstrict
local SetType = require(script.Parent:WaitForChild("_SetType"))
type Set<T> = SetType.Set<T>

--- Converts a set of values to an array of those values.
local function ToArray<T>(Set: Set<T>): {T}
    local Result = {}

    for Key in Set do
        table.insert(Result, Key)
    end

    return Result
end

return ToArray