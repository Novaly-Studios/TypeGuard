local IsArray = require(script.Parent:WaitForChild("IsArray"))
local IsMap = require(script.Parent.Parent:WaitForChild("Map"):WaitForChild("IsMap"))

--- Checks if the input table has a map / dictionary component and no array component.
local function IsPureArray(Structure: {[any]: any}): boolean
    return IsArray(Structure) and not IsMap(Structure)
end

return IsPureArray