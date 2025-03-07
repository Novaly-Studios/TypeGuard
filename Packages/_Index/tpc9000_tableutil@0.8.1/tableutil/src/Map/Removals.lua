--!native
--!optimize 2
--!nonstrict

--- Finds keys in X which are not in Y (i.e. removed values with respect to a base table).
local function Removals<K, V>(X: {[K]: V}, Y: {[K]: V}): {[K]: V}
    if (next(X) == nil) then
        return X
    end

    if (next(Y) == nil) then
        return X
    end

    local Result = {}

    for Key, Value in X do
        if (Y[Key] == nil) then
            Result[Key] = Value
        end
    end

    return Result
end

return Removals