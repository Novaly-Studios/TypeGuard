--- Filters a table for all items which satisfy some condition.
local function Filter<K, V>(Structure: {[K]: V}, Condition: (V, K) -> boolean): {[K]: V}
    local Result = {}

    for Key, Value in Structure do
        if (Condition(Value, Key)) then
            Result[Key] = Value
        end
    end

    return Result
end

return Filter