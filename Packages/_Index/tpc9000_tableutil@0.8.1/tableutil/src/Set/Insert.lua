--!native
--!optimize 2
--!nonstrict

local SetType = require(script.Parent._SetType)
type Set<T> = SetType.Set<T>

--- Creates a new set with the given value inserted.
local function Insert<T>(Set1: Set<T>, Value: T): Set<T>
    if (Value == nil) then
        return Set1
    end

    if (Set1[Value]) then
        return Set1
    end

    local Result = table.clone(Set1)

    if (Value) then
        Result[Value] = true
    end

    return Result
end

return Insert