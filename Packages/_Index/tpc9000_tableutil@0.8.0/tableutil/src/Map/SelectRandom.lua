--!native
--!optimize 2
--!nonstrict

local RandomGen = Random.new()

--- Selects a random element from a flat array, along with its index. Takes optional random seed.
local function SelectRandom<K, V>(Map: {[K]: V}, Seed: number?): (V, K)
    local RandomObject = (Seed and Random.new(Seed) or RandomGen)
    local Array = {}
    local Count = 0

    for Key, Value in Map do
        table.insert(Array, Value)
        table.insert(Array, Key)
        Count += 1
    end

    local Index = RandomObject:NextInteger(1, Count) * 2
    return Array[Index - 1], Array[Index]
end

return SelectRandom