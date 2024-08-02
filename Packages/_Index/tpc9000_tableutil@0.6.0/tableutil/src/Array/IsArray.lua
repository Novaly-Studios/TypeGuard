--- Checks if the input table has an *array component*. Not mutually exclusive to IsMap.
local function IsArray(Structure: {[any]: any}): boolean
    return Structure[1] ~= nil
end

return IsArray