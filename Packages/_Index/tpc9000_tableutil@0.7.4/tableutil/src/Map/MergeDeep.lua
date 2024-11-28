--!native
--!optimize 2
--!nonstrict

--- Creates a new data structure, representing the recursive merge of one table into another.
--- Metatables are preserved, with new metatables overwrtiting old metatables.
--- Functions will map & replace respective values into the new table.
local function MergeDeep<K1, K2, V1, V2>(X: {[K1]: V1}, Y: {[K2]: V2}): {[K1 | K2]: V1 | V2}
    local Result = table.clone(X)
    local Equal = true

    for Key, Value in Y do
        local Type = type(Value)
        local OtherValue = Result[Key]
        local NewValue = (
            -- If it's a table...
            --      Doesn't already exist in the result -> put it in directly, no need to recurse or copy.
            --      Does already exist in the result -> recurse further and merge the two tables.
            (Type == "table" and (OtherValue and MergeDeep(OtherValue, Value) or Value)) or
            -- If it's a mapper function -> call it with the value and subtitute whatever it returns.
            (Type == "function" and Value(OtherValue)) or
            -- Otherwise, put value in directly.
            Value
        )
        Equal = (Equal and OtherValue == NewValue)
        Result[Key] = NewValue
    end

    local MT = getmetatable(Y :: any)
    if (MT) then
        Equal = Equal and (getmetatable(Result) == MT)
        if (not Equal) then
            setmetatable(Result, MT)
        end
    end

    return (Equal and X or Result)
end

return MergeDeep