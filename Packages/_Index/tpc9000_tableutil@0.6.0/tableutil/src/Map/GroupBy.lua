--- Groups elements of a table by a key returned by the grouper function. The grouper function is passed the value and key of each element.
--- Usage: GroupBy({A = 1, B = 2, C = 3}, function(Value, Key) return Value % 2 end) --> {[0] = {B = 2}, [1] = {A = 1, C = 3}}
local function GroupBy<EntryKey, Entry>(Structure: {[EntryKey]: Entry}, Grouper: ((Entry, EntryKey) -> (EntryKey))): {[EntryKey]: {Entry}}
    local Result = {}

    for Key, Value in Structure do
        local NewKey = Grouper(Value, Key)

        if (NewKey == nil) then
            continue
        end

        local Target = Result[NewKey]

        if (Target) then
            Target[Key] = Value
            continue
        end

        Result[NewKey] = {[Key] = Value}
    end

    return Result
end

return GroupBy