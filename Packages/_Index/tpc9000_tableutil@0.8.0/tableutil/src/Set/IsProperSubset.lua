--!native
--!optimize 2
--!nonstrict

local SetType = require(script.Parent._SetType)
type Set<T> = SetType.Set<T>

--- Returns true if both sets are not equal and the first set is a subset of the second set.
local function IsProperSubset<T>(Set1: Set<T>, Set2: Set<T>): boolean
    for Value in Set1 do
        if (not Set2[Value]) then
            return false
        end
    end

    for Value in Set2 do
        if (not Set1[Value]) then
            return true
        end
    end

    return false
end

return IsProperSubset