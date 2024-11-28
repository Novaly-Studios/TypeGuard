--!native
--!optimize 2
--!nonstrict

--- Shallow checks if both arrays have equal elements.
local function Equals<T>(X: {any}, Y: {any}): boolean
    if (#X ~= #Y) then
        return false
    end

    for Index, Value in X do
        if (Value ~= Y[Index]) then
            return false
        end
    end

    return true
end

return Equals