--- Obtains the keys from a table.
local function Keys<K>(Structure: {[K]: any}): {K}
    local Result = {}
    local Index = 1

    for Key in Structure do
        Result[Index] = Key
        Index += 1
    end

    return Result
end

return Keys