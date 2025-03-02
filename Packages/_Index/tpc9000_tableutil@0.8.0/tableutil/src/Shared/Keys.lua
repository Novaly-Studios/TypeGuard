--!native
--!optimize 2
--!nonstrict

--- Obtains the keys from a table.
local function Keys<K>(Structure: {[K]: any}): {K}
    local Result = {}

    for Key in Structure do
        table.insert(Result, Key)
    end

    return Result
end

return Keys