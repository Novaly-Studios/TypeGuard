--!native
--!optimize 2
--!nonstrict

--- Merges both given tables recursively.
--- Metatables are preserved, with new metatables overwrtiting old metatables.
local function MutableMergeDeep(X, Y)
    for Key, Value in Y do
        local Type = type(Value)

        if (Type == "table") then
            local Got = X[Key]
            if (not Got) then
                Got = {}
                X[Key] = Got
            end

            MutableMergeDeep(Got, Value)
            continue
        elseif (Type == "function") then
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