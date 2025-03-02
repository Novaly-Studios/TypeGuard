--!native
--!optimize 2
--!nonstrict

--- Flattens a deep table, merging all sub-tables into the top level. Takes an optional depth limit.
local function Flatten(Structure: any, DepthLimit: number?)
    DepthLimit = DepthLimit or math.huge

    if (DepthLimit == 0) then
        return
    end

    local Result = {}

    for Key, Value in Structure do
        if (type(Value) == "table") then
            local Flattened = Flatten(Value, DepthLimit :: number - 1)
            if (Flattened) then
                for FlattenedKey, FlattenedValue in Flattened do
                    Result[FlattenedKey] = FlattenedValue
                end
            end
        else
            Result[Key] = Value
        end
    end

    return Result
end

return Flatten