--!native
--!optimize 2
--!nonstrict

--- Finds unequal values with the same key, returns a table of the new values from Y.
--- Nil values are ignored.
local function Changes<K, V>(X: {[K]: V}, Y: {[K]: V}): {[K]: V}
    local Result = {}

    for Key, Value in X do
        local YValue = Y[Key]
        if (YValue == nil) then
            continue
        end
        if (YValue == Value) then
            continue
        end
        Result[Key] = YValue
    end

    return Result
end

return Changes