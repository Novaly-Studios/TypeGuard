local function MutableMergeDeep(Into, Data)
    for Key, Value in Data do
        if (typeof(Value) == "table") then
            local Got = Into[Key]

            if (not Got) then
                Got = {}
                Into[Key] = Got
            end

            MutableMergeDeep(Got, Value)
            continue
        end

        Into[Key] = Value
    end
end

return MutableMergeDeep