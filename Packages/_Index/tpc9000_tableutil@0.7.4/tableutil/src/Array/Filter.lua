--!native
--!optimize 2
--!nonstrict

--- Filters an array for all items which satisfy some condition.
local function Filter<T>(Array: {T}, Condition: (T, number) -> boolean, Allocate: number?): {T}
    local Result = table.create(Allocate or 0)
    local Equals = true
    local Index = 1

    for ItemIndex, Value in Array do
        if (Condition(Value, ItemIndex)) then
            Result[Index] = Value
            Index += 1
        else
            Equals = false
        end
    end

    return (Equals and Array or Result)
end

return Filter