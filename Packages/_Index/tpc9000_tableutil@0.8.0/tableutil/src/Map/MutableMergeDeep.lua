--!native
--!optimize 2
--!nonstrict

--- Merges both given tables recursively.
--- Metatables are preserved, with new metatables overwrtiting old metatables.
local function MutableMergeDeep(X, Y, FunctionsMap: boolean?)
    for Key, Value in Y do
        local Type = type(Value)

        if (Type == "table") then
            local LeftValue = X[Key]

            if (type(LeftValue) == "table") then
                MutableMergeDeep(LeftValue, Value, FunctionsMap)
                continue
            end
        elseif (FunctionsMap and Type == "function") then
            Value = Value(X[Key])
        end

        X[Key] = Value
    end

    local MT = getmetatable(Y :: any)
    if (MT) then
        setmetatable(X, MT)
    end
end

return MutableMergeDeep