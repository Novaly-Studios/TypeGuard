--!nonstrict
local SetType = require(script.Parent:WaitForChild("_SetType"))
type Set<T> = SetType.Set<T>

--- Returns true if all elements in the first set are also in the second set.
local function IsSubset<T>(Set1: Set<T>, Set2: Set<T>): boolean
    for Value in Set1 do
        if (not Set2[Value]) then
            return false
        end
    end

    return true
end

return IsSubset