--!native
--!optimize 2
--!nonstrict

-- Todo: support to-overwrite metatables in this.

--- Creates a "patch template" into another object recursively.
--- This allows us to apply an additional merge to add new fields to values which were not originally nil.
--- Good use case: want to merge in new default fields to a player's data without overwriting existing fields.
local function CreatePatchDeep(Existing, Template)
    local Result = {}

    for Key, Value in Template do
        local ExistingValue = Existing[Key]
        local ExistingValueIsTable = (typeof(ExistingValue) == "table")
        local ValueIsTable = (typeof(Value) == "table")

        if (ExistingValueIsTable and ValueIsTable) then
            Result[Key] = CreatePatchDeep(ExistingValue, Value)
            continue
        end

        if (ExistingValueIsTable) then
            Result[Key] = Value
            continue
        end

        if (ExistingValue == nil) then
            if (ValueIsTable) then
                Result[Key] = CreatePatchDeep({}, Value)
            else
                Result[Key] = Value
            end

            continue
        end

        if (ValueIsTable) then
            error("Attempt to merge table into non-table value")
        end
    end

    return Result
end

return CreatePatchDeep