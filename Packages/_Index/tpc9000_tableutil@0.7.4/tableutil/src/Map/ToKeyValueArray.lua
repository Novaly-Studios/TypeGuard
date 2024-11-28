--!native
--!optimize 2
--!nonstrict

--- Converts a table into an array of key-value objects.
local function ToKeyValueArray<K, V>(Structure: {[K]: V}): {{Key: K, Value: V}}
    local Result = {}
    for Key, Value in Structure do
        table.insert(Result, {Key = Key, Value = Value})
    end
    return Result
end

return ToKeyValueArray