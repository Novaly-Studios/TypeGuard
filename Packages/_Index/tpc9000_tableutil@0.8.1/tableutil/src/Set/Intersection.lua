--!native
--!optimize 2
--!nonstrict

local SetType = require(script.Parent._SetType)
type Set<T> = SetType.Set<T>

--- Returns a new set, containing the elements that are in both sets.
local function Intersection<T>(Set1: Set<T>, Set2: Set<T>): Set<T>
    if (next(Set1) == nil) then
        return Set1
    end

    if (next(Set2) == nil) then
        return Set2
    end

    local Result = {}

    for Key in Set1 do
        if (Set2[Key] and Set1[Key]) then
            Result[Key] = true
        end
    end

    return Result
end

return Intersection