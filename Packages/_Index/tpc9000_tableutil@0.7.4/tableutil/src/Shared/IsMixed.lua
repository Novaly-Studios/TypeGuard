--!native
--!optimize 2
--!nonstrict

local IsMap = require(script.Parent.IsMap)
local IsArray = require(script.Parent.IsArray)

--- Checks if the input table has both a map / dictionary component, and an array component.
local function IsMixed(Structure: {[any]: any}): boolean
    return IsMap(Structure) and IsArray(Structure)
end

return IsMixed