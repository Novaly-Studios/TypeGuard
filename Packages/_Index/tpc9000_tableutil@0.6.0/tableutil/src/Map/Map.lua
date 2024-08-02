--- Puts each key-value pair in a table through a transformation function, mapping the outputs into a new table.
local function Map<K, V, KT, VT>(Structure: {[K]: V}, Operation: (V, K) -> (VT?, KT?)): {[KT | K]: VT}
    local Result = {}

    for Key, Value in Structure do
        local NewValue, NewKey = Operation(Value, Key)
        Result[NewKey or Key] = NewValue
    end

    return Result
end

return Map