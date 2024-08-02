--!nonstrict
local SetType = require(script.Parent:WaitForChild("_SetType"))
type Set<T> = SetType.Set<T>

--- Creates a new set with the given value removed.
local function Remove<T>(Set1: Set<T>, Value: T): Set<T>
    if (Value == nil) then
        return Set1
    end

    if (next(Set1) == nil) then
        return Set1
    end

    if (Set1[Value] == nil) then
        return Set1
    end

    local Result = {}

    for Key in Set1 do
        Result[Key] = true
    end

    Result[Value] = nil

    return Result
end

return Remove