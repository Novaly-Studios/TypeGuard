--!native
--!optimize 2
--!nonstrict

local IsArray = require(script.Parent.IsArray)
local IsMap = require(script.Parent.IsMap)

--- Checks if the input table has an array component and no map / dictionary component.
local function IsPureMap(Structure: {[any]: any}): boolean
    return IsMap(Structure) and not IsArray(Structure)
end

return IsPureMap