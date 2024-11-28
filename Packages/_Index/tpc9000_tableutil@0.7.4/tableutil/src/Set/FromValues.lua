--!native
--!optimize 2
--!nonstrict

local SetType = require(script.Parent._SetType)
type Set<T> = SetType.Set<T>

--- Creates a new set from a table of values.
local function FromValues<T>(ValuesTable: {[any]: T}): Set<T>
    local Result = {}
    for _, Value in ValuesTable do
        Result[Value] = true
    end
    return Result
end

return FromValues