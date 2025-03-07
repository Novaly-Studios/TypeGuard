--!native
--!optimize 2
--!nonstrict

--- Selects the first item in an array which satisfies some condition.
local function SelectFirst<T>(Array: {T}, Condition: (T, number) -> boolean): (T?, number?)
    for Index, Value in Array do
        if (Condition(Value, Index)) then
            return Value, Index
        end
    end

    return nil, nil
end

return SelectFirst