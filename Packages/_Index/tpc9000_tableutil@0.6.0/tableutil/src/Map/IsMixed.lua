local IsMap = require(script.Parent:WaitForChild("IsMap"))
local IsArray = require(script.Parent.Parent:WaitForChild("Array"):WaitForChild("IsArray"))

--- Checks if the input table has both a map / dictionary component, and an array component.
local function IsMixed(Structure: {[any]: any}): boolean
    return IsMap(Structure) and IsArray(Structure)
end

return IsMixed