--!native
--!optimize 2
--!nonstrict

--- Merges two tables together, returning a new one.
--- Metatables are preserved, with new metatables overwrtiting old metatables.
local function Merge<K1, K2, V1, V2>(X: {[K1]: V1}, Y: {[K2]: V2}, FunctionsMap: boolean?): {[K1 | K2]: V1 | V2}
    if (next(Y) == nil and getmetatable(Y :: any) == nil) then
        return X
    end

    if (next(X) == nil and getmetatable(X :: any) == nil) then
        return Y
    end

    if (X == Y) then
        return X
    end

    local Result = table.clone(X)
    local Equals = true

    for Key, Value in Y do
        local OtherValue = Result[Key]
        local NewValue

        if (FunctionsMap and type(Value) == "function") then
            -- If it's a mapper function, call it with the value and subtitute whatever it returns.
            NewValue = Value(OtherValue)
        else
            -- Otherwise, put value in directly.
            NewValue = Value
        end

        Equals = (Equals and OtherValue == NewValue)
        Result[Key] = NewValue
    end

    local MT = getmetatable(Y :: any)

    if (MT) then
        Equals = Equals and (getmetatable(Result) == MT)

        if (not Equals) then
            setmetatable(Result, MT)
        end
    end

    return (Equals and X or Result)
end

return Merge