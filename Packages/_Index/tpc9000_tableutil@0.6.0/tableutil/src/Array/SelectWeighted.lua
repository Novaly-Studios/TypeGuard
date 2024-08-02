local RandomGen = Random.new()

--- Selects a random value from the given array, weighted by the given weights.
--- WeightKey defines the index in each sub-object that contains the weight.
local function SelectWeighted1D<V>(Array: {V & {}}, WeightKey: string, Seed: number?, SortMutate: boolean?): V
    local UseRandom = (Seed and Random.new(Seed) or RandomGen)
    local TotalWeight = 0

    if (not SortMutate) then
        Array = table.clone(Array)
    end

    for _, Value in Array do
        TotalWeight += Value[WeightKey]
    end

    table.sort(Array, function(A, B)
        return A[WeightKey] > B[WeightKey]
    end)

    local RandomWeight = UseRandom:NextNumber() * TotalWeight

    for _, Value in Array do
        RandomWeight -= Value[WeightKey]

        if (RandomWeight <= 0) then
            return Value
        end
    end

    error("Failed to select weighted value.") -- This should be impossible... stops type checking from complaining though.
end

return SelectWeighted1D