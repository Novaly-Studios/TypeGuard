--!native
--!optimize 2
--!nonstrict

local SetType = require(script.Parent._SetType)
type Set<T> = SetType.Set<T>

--- Returns a new set, containing the elements that are in Set1, but not in Set2.
local function Difference<T>(Set1: Set<T>, Set2: Set<T>): Set<T>
    if (Set1 == Set2) then
        return {}
    end

    if (next(Set2) == nil) then
        return Set1
    end

    if (next(Set1) == nil) then
        return Set1
    end

    local Result = {}

    for Key in Set1 do
        if (Set2[Key] == nil) then
            Result[Key] = true
        end
    end

    return Result
end

return Difference