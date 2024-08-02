--- Creates a new data structure, representing the recursive merge of one table into another. Ensures structural sharing.
local function MergeDeep<K1, K2, V1, V2>(Into: {[K1]: V1}, Data: {[K2]: V2}): {[K1 | K2]: V1 | V2}
    if (next(Into) == nil) then
        return Data
    end

    if (next(Data) == nil) then
        return Into
    end

    if (Into == Data) then
        return Into
    end

    local Result = {}

    for Key, Value in Into do
        Result[Key] = Value
    end

    for Key, Value in Data do
        Result[Key] = (type(Value) == "table" and MergeDeep(Result[Key] or {}, Value) or Value)
    end

    return Result
end

return MergeDeep