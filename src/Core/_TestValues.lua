local Types = {
    Function = function() end;
    Boolean = false;
    Buffer = buffer.create(10);
    Number = 100;
    Float = 100.5;
    String = "Test";
    Thread = task.spawn(function() end);
    Userdata = newproxy(true);
    ["Rbx-BrickColor"] = BrickColor.Red();
    ["Rbx-CFrame"] = CFrame.new(1, 1, 1);
    ["Rbx-Color3"] = Color3.new(1, 1, 1);
    ["Rbx-ColorSequence"] = ColorSequence.new(Color3.new(1, 1, 1));
    ["Rbx-ColorSequenceKeypoint"] = ColorSequenceKeypoint.new(0, Color3.new(1, 1, 1));
    ["Rbx-EnumItem"] = Enum.KeyCode;
    ["Rbx-Enum"] = Enum.KeyCode.A;
    ["Rbx-Instance"] = Instance.new("Folder");
    ["Rbx-NumberSequence"] = NumberSequence.new(1);
    ["Rbx-NumberSequenceKeypoint"] = NumberSequenceKeypoint.new(1, 1, 1);
    ["Rbx-NumberRange"] = NumberRange.new(1.25, 5.5);
    ["Rbx-Ray"] = Ray.new(Vector3.new(0, 0, 0), Vector3.new(1, 1, 1));
    ["Rbx-TweenInfo"] = TweenInfo.new(5, Enum.EasingStyle.Linear);
    ["Rbx-UDim1"] = UDim.new(1, 1);
    ["Rbx-UDim2"] = UDim2.new(1, 1, 1, 1);
    ["Rbx-Vector2"] = Vector2.new(1, 1);
    ["Rbx-Vector3"] = Vector3.new(1, 1, 1);
    ["Rbx-Axes"] = Axes.new(Enum.NormalId.Front);
    ["Rbx-Content"] = Content.fromUri("rbxassetid://12345");
    ["Rbx-DateTime"] = DateTime.fromUnixTimestamp(1741139693);
    ["Rbx-Faces"] = Faces.new(Enum.NormalId.Top);
    ["Rbx-Font"] = Font.new("Test");
    ["Rbx-OverlapParams"] = OverlapParams.new();
    ["Rbx-Path2DControlPoint"] = Path2DControlPoint.new(UDim2.new(1, 1, 1, 1), UDim2.new(1, 1, 1, 1), UDim2.new(1, 1, 1, 1));
    ["Rbx-PathWaypoint"] = PathWaypoint.new(Vector3.new(1, 1, 1), Enum.PathWaypointAction.Walk, "Hello");
    ["Rbx-PhysicalProperties"] = PhysicalProperties.new(Enum.Material.Sandstone);
    ["Rbx-RaycastParams"] = RaycastParams.new();
    ["Rbx-Rect"] = Rect.new(Vector2.zero, Vector2.one);
    ["Rbx-Region3"] = Region3.new(Vector3.new(10, 10, 10), Vector3.new(20, 20, 20));
    ["Rbx-RotationCurveKey"] = RotationCurveKey.new(1.5, CFrame.new(1, 2, 3), Enum.KeyInterpolationMode.Cubic);
    --[[ ["Rbx-SharedTable"] = SharedTable.new({X = 1, Y = "2"}); ]]
}
local FullTypes = table.clone(Types)

for TypeName1, Value1 in Types do
    for TypeName2, Value2 in Types do
        FullTypes[`Map-{TypeName1}-{TypeName2}`] = {[Value1] = Value2, [Value2] = Value1}
        FullTypes[`Array-{TypeName1}-{TypeName2}`] = {Value1, Value2}
        --[[ FullTypes[`Mixed-{TypeName1}-{TypeName2}`] = {[0] = Value1, [1] = Value2, Other = Value1, [Value2] = Value2} ]]
    end
end

local function IncludeGet(...: string)
    local Final = table.clone(FullTypes)

    for Index = 1, select("#", ...) do
        local Pattern = (select(Index, ...))
        local Remove = {}

        for Key in Final do
            if (not string.match(Key, Pattern)) then
                table.insert(Remove, Key)
            end
        end

        for _, Key in Remove do
            Final[Key] = nil
        end
    end

    return Final
end

local function Get(...: string)
    local Final = table.clone(FullTypes)

    if ((select(1, ...)) == "INCLUDE") then
        return IncludeGet(select(2, ...))
    end

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