local RandomGenerator = Random.new()

--- Scrambles an array with an optional random seed.
local function MutableShuffle<T>(Array: {T}, Seed: number?)
    local Generator = Seed and Random.new(Seed) or RandomGenerator
    local ArraySize = #Array

    for Index = 1, ArraySize do
        local Generated = Generator:NextInteger(1, ArraySize)
        Array[Index], Array[Generated] = Array[Generated], Array[Index]
    end
end

return MutableShuffle