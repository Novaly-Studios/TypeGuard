--!native
--!optimize 2
--!nonstrict

local SetType = require(script.Parent._SetType)
type Set<T> = SetType.Set<T>

--- Creates a new set from a table of keys.
local function FromKeys<T>(KeysTable: {[T]: any}): Set<T>
    local Result = {}
    for Key in KeysTable do
        Result[Key] = true
    end
    return Result
end

return FromKeys