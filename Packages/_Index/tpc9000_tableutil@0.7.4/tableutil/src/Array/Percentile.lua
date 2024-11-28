--!native
--!optimize 2
--!nonstrict

local function Percentile<T>(OrderedArray: {T}, Percentile: number): T
    return OrderedArray[math.ceil(#OrderedArray * Percentile)]
end

return Percentile