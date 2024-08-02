--!nonstrict
local SetType = require(script.Parent:WaitForChild("_SetType"))
type Set<T> = SetType.Set<T>

--- Returns a new set, containing the elements that are in both sets.
local function Intersection<T>(Set1: Set<T>, Set2: Set<T>): Set<T>
    local Result = {}

    for Key in Set1 do
        if (Set2[Key] and Set1[Key]) then
            Result[Key] = true
        end
    end

    return Result
end

return Intersection