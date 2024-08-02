local Types = {
    Function = function() end;
    Boolean = false;
    Buffer = buffer.create(10);
    Number = 3007.24253;
    String = "Test";
    Thread = task.spawn(function() end);
    ["Rbx-CFrame"] = CFrame.new(1, 1, 1);
    ["Rbx-Color3"] = Color3.new(1, 1, 1);
    ["Rbx-ColorSequence"] = ColorSequence.new(Color3.new(1, 1, 1));
    ["Rbx-ColorSequenceKeypoint"] = ColorSequenceKeypoint.new(0, Color3.new(1, 1, 1));
    ["Rbx-EnumItem"] = Enum.KeyCode;
    ["Rbx-Enum"] = Enum.KeyCode.A;
    ["Rbx-Instance"] = Instance.new("Folder");
    ["Rbx-NumberSequence"] = NumberSequence.new(1);
    ["Rbx-NumberSequenceKeypoint"] = NumberSequenceKeypoint.new(1, 1, 1);
    ["Rbx-Ray"] = Ray.new(Vector3.new(0, 0, 0), Vector3.new(1, 1, 1));
    ["Rbx-TweenInfo"] = TweenInfo.new(5, Enum.EasingStyle.Linear);
    ["Rbx-UDim1"] = UDim.new(1, 1);
    ["Rbx-UDim2"] = UDim2.new(1, 1, 1, 1);
    ["Rbx-Vector2"] = Vector2.new(1, 1);
    ["Rbx-Vector3"] = Vector3.new(1, 1, 1);
}
local FullTypes = table.clone(Types)
for TypeName1, Value1 in Types do
    for TypeName2, Value2 in Types do
        FullTypes[`Object-{TypeName1}-{TypeName2}`] = {{[Value1] = Value2, [Value2] = Value1}, {[Value1] = Value2}, {[Value2] = Value1}}
        FullTypes[`Array-{TypeName1}-{TypeName2}`] = {{Value1, Value2}, {Value2, Value1}}
    end
end

local function Get(...: string)
    local Final = table.clone(FullTypes)

    for Index = 1, select("#", ...) do
        local Pattern = (select(Index, ...))
        local Remove = {}

        for Key in Final do
            if (string.match(Key, Pattern)) then
                table.insert(Remove, Key)
            end
        end

        for _, Key in Remove do
            Final[Key] = nil
        end
    end

    return Final
end

return Get