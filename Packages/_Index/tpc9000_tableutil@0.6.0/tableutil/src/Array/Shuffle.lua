local MutableShuffle = require(script.Parent:WaitForChild("MutableShuffle"))

--- Scrambles an array with an optional random seed.
local function Shuffle<T>(Array: {T}, Seed: number?): {T}
    local Copy = table.clone(Array)
    MutableShuffle(Copy, Seed)
    return Copy
end

return Shuffle