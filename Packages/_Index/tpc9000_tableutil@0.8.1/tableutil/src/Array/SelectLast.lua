--!native
--!optimize 2
--!nonstrict

--- Selects the last item in an array which satisfies some condition.
local function SelectLast<T>(Array: {T}, Condition: (T, number) -> boolean): (T?, number?)
    for Index = #Array, 1, -1 do
        local Value = Array[Index]

        if (Condition(Value, Index)) then
            return Value, Index
        end
    end

    return nil, nil
end

return SelectLast