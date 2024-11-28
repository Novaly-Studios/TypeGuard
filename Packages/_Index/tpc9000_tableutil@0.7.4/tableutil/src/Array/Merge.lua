--!native
--!optimize 2
--!nonstrict

--- Merges two arrays together.
local function Merge<V1, V2>(Into: {V1}, New: {V2}): {V1 | V2}
    local IntoSize = #Into
    if (IntoSize == 0) then
        return New
    end

    local NewSize = #New
    if (NewSize == 0) then
        return Into
    end

    if (Into == New) then
        return Into
    end

    local Result = table.clone(Into)
    table.move(New, 1, NewSize, IntoSize + 1, Result)
    return Result
end

return Merge