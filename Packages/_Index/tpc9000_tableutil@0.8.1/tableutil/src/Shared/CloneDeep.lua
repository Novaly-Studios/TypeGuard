--!native
--!optimize 2
--!nonstrict

--- Copies a data structure on all depth levels.
--- If you're using this function you might be doing something wrong - recommend only cloning the sub-tables which change.
local function CloneDeep<K, V>(Structure: {[K]: V}): {[K]: V}
    local Result = table.clone(Structure)

    for Key, Value in Structure do
        if (type(Value) == "table") then
            Result[Key] = CloneDeep(Value)
        end
    end

    return Result
end

return CloneDeep