--!native
--!optimize 2
--!nonstrict

local RandomGen = Random.new()

--- Selects a random element from a flat array, along with its index. Takes optional random seed.
local function SelectRandom<T>(Array: {[number]: T}, Seed: number?): (T, number)
    local RandomObject = (Seed and Random.new(Seed) or RandomGen)
    local Index = RandomObject:NextInteger(1, #Array)
    return Array[Index], Index
end

return SelectRandom