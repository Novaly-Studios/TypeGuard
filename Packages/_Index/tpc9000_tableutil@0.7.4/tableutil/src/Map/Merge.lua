--!native
--!optimize 2
--!nonstrict

--- Merges two tables together, returning a new one.
--- Metatables are preserved, with new metatables overwrtiting old metatables.
local function Merge<K1, K2, V1, V2>(X: {[K1]: V1}, Y: {[K2]: V2}): {[K1 | K2]: V1 | V2}
    local Result = table.clone(X)
    local Equal = true

    for Key, Value in Y do
        local OtherValue = Result[Key]
        local NewValue = (
            -- If it's a mapper function -> call it with the value and subtitute whatever it returns.
            (type(Value) == "function" and Value(OtherValue)) or
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

return Merge