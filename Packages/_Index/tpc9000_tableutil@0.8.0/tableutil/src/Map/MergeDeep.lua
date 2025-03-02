--!native
--!optimize 2
--!nonstrict

--- Creates a new data structure, representing the recursive merge of one table into another.
--- Metatables are preserved, with new metatables overwrtiting old metatables.
--- Functions will map & replace respective values into the new table.
local function MergeDeep<K1, K2, V1, V2>(X: {[K1]: V1}, Y: {[K2]: V2}, FunctionsMap: boolean?, SelfCall): {[K1 | K2]: V1 | V2}
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
        local Type = type(Value)
        local LeftValue = Result[Key]
        local NewValue
        
        if (Type == "table" and type(LeftValue) == "table") then
            -- If both values are tables, recurse further and merge the two tables.
            NewValue = (SelfCall or MergeDeep)(LeftValue, Value, FunctionsMap, SelfCall)
        elseif (FunctionsMap and Type == "function") then
            -- If it's a mapper function, call it with the value and substitute whatever it returns.
            NewValue = Value(LeftValue)
        else
            -- Otherwise, put value in directly.
            NewValue = Value
        end
        
        Equals = (Equals and LeftValue == NewValue)
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

return MergeDeep