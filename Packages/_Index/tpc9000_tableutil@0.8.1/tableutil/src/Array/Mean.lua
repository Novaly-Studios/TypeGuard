--!native
--!optimize 2
--!nonstrict

local function Mean<T>(Array: {T}, From: number?, To: number?): T
    From = From or 1
    To = To or #Array

    local Mean = 0

    if (To > 0) then
        for Index = From :: number, To :: number do
            Mean += Array[Index]
        end
    end

    return Mean / math.max(1, To :: number - From :: number + 1)
end

return Mean