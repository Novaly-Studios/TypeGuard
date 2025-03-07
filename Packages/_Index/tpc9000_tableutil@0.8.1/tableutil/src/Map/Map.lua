--!native
--!optimize 2
--!nonstrict

--- Puts each key-value pair in a table through a transformation function, mapping the outputs into a new table.
local function Map<K, V, KT, VT>(Structure: {[K]: V}, Operator: (V, K) -> (VT?, KT?)): {[KT | K]: VT}
    local Result = {}
    local Equals = true

    for Key, Value in Structure do
        local NewValue, NewKey = Operator(Value, Key)
        local FinalKey = NewKey or Key
        Result[FinalKey] = NewValue

        if (Structure[FinalKey] ~= NewValue) then
            Equals = false
        end
    end

    return (Equals and (Structure :: any) or Result)
end

return Map