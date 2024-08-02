local IsArray = require(script.Parent.Parent:WaitForChild("Array"):WaitForChild("IsArray"))
local IsMap = require(script.Parent:WaitForChild("IsMap"))

--- Checks if the input table has an array component and no map / dictionary component.
local function IsPureMap(Structure: {[any]: any}): boolean
    return IsMap(Structure) and not IsArray(Structure)
end

return IsPureMap