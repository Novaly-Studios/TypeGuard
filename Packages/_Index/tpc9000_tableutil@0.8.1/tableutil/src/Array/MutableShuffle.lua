--!native
--!optimize 2
--!nonstrict

local RandomGenerator = Random.new()

--- Scrambles an array with an optional random seed.
local function MutableShuffle<T>(Array: {T}, Seed: number?)
    (Seed and Random.new(Seed) or RandomGenerator):Shuffle(Array)
end

return MutableShuffle