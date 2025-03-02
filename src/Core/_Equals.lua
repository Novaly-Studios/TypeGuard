--!optimize 2
--!native

local RobloxTypes = {
    CFrame = true;
    Color3 = true;
    ColorSequence = true;
    ColorSequenceKeypoint = true;
    EnumItem = true;
    Enum = true;
    Instance = true;
    NumberSequence = true;
    NumberSequenceKeypoint = true;
    Ray = true;
    TweenInfo = true;
    UDim = true;
    UDim2 = true;
    Vector2 = true;
    Vector3 = true;
}

local function SimpleEncode(Target)
    local Type = typeof(Target)

    if (Type == "buffer") then
        return true, `<buffer>{buffer.tostring(Target)}`
    end

    if (RobloxTypes[Type]) then
        return true, `<{Type}>{Target}`
    end

    return false, Target
end

-- Some types like buffers can't be directly == compared on their contents, so we have to do this.
local function ReduceToComparable(Target)
    if (typeof(Target) ~= "table") then
        return select(2, SimpleEncode(Target))
    end

    local Copy = table.clone(Target)

    for Key, Value in Target do
        local KeySuccess, NewKey = SimpleEncode(Key)
        if (KeySuccess) then
            Copy[Key] = nil
            Key = NewKey
        end

        local ValueType = typeof(Value)
        if (ValueType == "table") then
            Copy[Key] = ReduceToComparable(Value)
            continue
        end

        local ValueSuccess, NewValue = SimpleEncode(Value)
        if (ValueSuccess) then
            Value = NewValue
        end

        Copy[Key] = Value
    end

    return Copy
end

local function DeepEquals(X, Y)
    local XType = typeof(X)
    local YType = typeof(Y)

    if (XType == "table" and YType == "table") then
        for Key, Value in X do
            if (Y[Key] == nil) then
                return false
            end

            if (not DeepEquals(Value, Y[Key])) then
                return false
            end
        end

        for Key in Y do
            if (X[Key] == nil) then
                return false
            end
        end

        return true
    end

    return (X == Y)
end

return function(X, Y)
    return DeepEquals(ReduceToComparable(X), ReduceToComparable(Y))
end