--!native
--!optimize 2
--!nonstrict

--- Produces a table of all possible combinations of values up to a given dimension.
local function Product(Array, Dimension)
    local Result = table.create((#Array) ^ Dimension)
    local Is1D = (Dimension == 1)

    for _, Value in Array do
        if (Is1D) then
            table.insert(Result, {Value})
            continue
        end

        for _, SubValue in Product(Array, Dimension - 1) do
            local Temp = table.create(#SubValue + 1)
            table.insert(Temp, Value)
            table.move(SubValue, 1, #SubValue, 2, Temp)
            table.insert(Result, Temp)
        end
    end

    return Result
end

return Product