--- Checks if the input table has a map / dictionary component. Not mutually exclusive to IsArray.
local function IsMap(Structure: {[any]: any}): boolean
    local Size = #Structure

    if (Size == 0) then
        return next(Structure) ~= nil
    end

    local Key = next(Structure, Size)

    if (Key == nil or (typeof(Key) == "number" and Key == 1)) then
        return false
    end

    return true
end

return IsMap