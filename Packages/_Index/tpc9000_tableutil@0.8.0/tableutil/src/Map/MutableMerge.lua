--!native
--!optimize 2
--!nonstrict

--- Merges two tables together.
--- Metatables are preserved, with new metatables overwrtiting old metatables.
local function MutableMerge(X: {[any]: any}, Y: {[any]: any}, FunctionsMap: boolean?)
    for Key, Value in Y do
        X[Key] = (
            if (FunctionsMap and type(Value) == "function") then
                Value(X[Key])
            else
                Value
        )
    end

    local MT = getmetatable(Y :: any)
    if (MT) then
        setmetatable(X, MT)
    end
end

return MutableMerge