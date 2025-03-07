--!native
--!optimize 2
--!nonstrict

--- Obtains the values from a table.
local function Values<T>(Structure: {[any]: T}): {T}
    local Result = {}

    for _, Value in Structure do
        table.insert(Result, Value)
    end

    return Result
end

return Values