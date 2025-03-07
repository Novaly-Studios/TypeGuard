--!native
--!optimize 2
--!nonstrict

local function Sum<T>(Array: {T}, From: number?, To: number?): T
    local Sum = 0
    local Size = #Array
    From = From or 1
    To = To or Size

    for Index = From :: number, To :: number, (To > From and 1 or -1) do
        Sum += Array[Index]
    end

    return Sum
end

return Sum