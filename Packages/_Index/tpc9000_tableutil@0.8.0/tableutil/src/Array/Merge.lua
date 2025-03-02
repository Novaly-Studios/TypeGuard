--!native
--!optimize 2
--!nonstrict

--- Merges two arrays together.
local function Merge<V1, V2>(Into: {V1}, New: {V2}): {V1 | V2}
    local NewSize = #New
    if (NewSize == 0) then
        return Into
    end

    local IntoSize = #Into
    if (IntoSize == 0) then
        return New
    end

    local Result = table.clone(Into)
    table.move(New, 1, NewSize, IntoSize + 1, Result)
    return Result
end

return Merge