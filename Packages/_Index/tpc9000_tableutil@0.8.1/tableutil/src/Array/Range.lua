--!native
--!optimize 2
--!nonstrict

local function Range(Min: number, Max: number): {number}
    local Result = table.create(Max - Min + 1)

    for Count = Min, Max do
        table.insert(Result, Count)
    end

    return Result
end

return Range