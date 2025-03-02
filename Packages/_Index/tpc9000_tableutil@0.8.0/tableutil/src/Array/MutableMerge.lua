--!native
--!optimize 2
--!nonstrict

--- Merges the second given array into the first.
local function MutableMerge(Into: {any}, New: {any})
    table.move(New, 1, #New, #Into + 1, Into)
end

return MutableMerge