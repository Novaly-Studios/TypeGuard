--!native
--!optimize 2
--!nonstrict

--- Filters a table for all items which satisfy some condition.
local function Filter<K, V>(Structure: {[K]: V}, Predicate: ((V, K) -> (boolean))): {[K]: V}
    local Result = {}
    local Equals = true

    for Key, Value in Structure do
        if (Predicate(Value, Key)) then
            Result[Key] = Value
        else
            Equals = false
        end
    end

    return (Equals and Structure or Result)
end

return Filter