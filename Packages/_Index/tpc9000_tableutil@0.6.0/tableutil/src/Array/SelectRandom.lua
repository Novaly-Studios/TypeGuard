local RandomGen = Random.new()

--- Selects a random element from a flat array, along with its index. Takes optional random seed.
local function SelectRandom<T>(Structure: {[number]: T}, Seed: number?): (T, number)
    local RandomObject = Seed and Random.new(Seed) or RandomGen
    local Index = RandomObject:NextInteger(1, #Structure)
    return Structure[Index], Index
end

return SelectRandom