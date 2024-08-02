local MutableMerge = require(script.Parent:WaitForChild("MutableMerge"))

--- Merges two tables together, returning a new one.
local function Merge<K1, K2, V1, V2>(X: {[K1]: V1}, Y: {[K2]: V2}): {[K1 | K2]: V1 | V2}
    if (next(X) == nil) then
        return Y
    end

    if (next(Y) == nil) then
        return X
    end

    local Result = {}
    MutableMerge(Result, X)
    MutableMerge(Result, Y)
    return Result
end

return Merge