--- Copies a data structure on the top level.
local function Clone<K, V>(Structure: {[K]: V}): {[K]: V}
    local Result = {}

    for Key, Value in Structure do
        Result[Key] = Value
    end

    return Result
end

return Clone