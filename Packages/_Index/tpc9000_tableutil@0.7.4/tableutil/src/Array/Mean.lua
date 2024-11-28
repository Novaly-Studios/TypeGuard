--!native
--!optimize 2
--!nonstrict

local function Mean<T>(Array: {T}, From: number?, To: number?): T
    From = From or 1
    To = To or #Array

    local Mean = 0
    for Index = From :: number, To :: number do
        Mean += Array[Index]
    end
    return Mean == 0 and Mean or Mean / (To :: number - From :: number + 1)
end

return Mean