--- Selects the first item in an array which satisfies some condition.
local function SelectFirst<T>(Array: {T}, Condition: (T, number) -> boolean): (T?, number?)
    for Index = 1, #Array do
        local Value = Array[Index]

        if (Condition(Value, Index)) then
            return Value, Index
        end
    end

    return nil, nil
end

return SelectFirst