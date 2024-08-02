--- Merges two tables together.
local function MutableMerge(X: {[any]: any}, Y: {[any]: any})
    for Key, Value in Y do
        X[Key] = Value
    end
end

return MutableMerge