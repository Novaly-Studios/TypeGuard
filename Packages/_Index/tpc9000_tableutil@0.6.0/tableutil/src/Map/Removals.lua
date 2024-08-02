--- Finds keys in X which are not in Y (i.e. removed values with respect to a base table).
local function Removals<K, V>(X: {[K]: V}, Y: {[K]: V}): {[K]: V}
    local Result = {}

    for Key, Value in X do
        if (Y[Key] == nil) then
            Result[Key] = Value
        end
    end

    return Result
end

return Removals