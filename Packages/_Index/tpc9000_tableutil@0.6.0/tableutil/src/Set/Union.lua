--!nonstrict
local SetType = require(script.Parent:WaitForChild("_SetType"))
type Set<T> = SetType.Set<T>

--- Merges two sets together.
local function Union<T>(Set1: Set<T>, Set2: Set<T>): Set<T>
    if (next(Set1) == nil) then
        return Set2
    end

    if (next(Set2) == nil) then
        return Set1
    end

    local Result = {}

    for Key in Set1 do
        Result[Key] = true
    end

    for Key in Set2 do
        Result[Key] = true
    end

    return Result
end

return Union