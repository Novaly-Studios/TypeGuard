--!optimize 2
--!native

local TypeGuard = require(game.ReplicatedFirst.TypeGuard)

local Test = {
    Clock = os.clock();
    Time = os.time();
    Test1 = true;
    Test2 = false;
    Test3 = "HHH";
    Array = {1, 2, "P", "Q", {AHH = 123}};

    Roblox = {
        Vector3 = Vector3.new(1, 2, 3.456);
        Color3 = Color3.new(1, 0.5, 0);
        CFrame = CFrame.new(1, 2, 3) * CFrame.Angles(math.rad(20), math.rad(30), math.rad(40));
    };
}
Test.Roblox2 = Test.Roblox
Test.Self = Test
Test.Roblox.Parent = Test
Test.Roblox.Self = Test.Roblox
Test.Roblox[Test.Roblox] = Test

--[[ local BaseAny = TypeGuard.BaseAny()
print(BaseAny:Deserialize(BaseAny:Serialize(Test, "Bit", false), "Bit", false)) ]]

--[[ local Any = TypeGuard.Any()
print(Any:Deserialize(Any:Serialize(Test, "Byte", false), "Byte", false)) ]]

--[[ local Serializer = TypeGuard.Any()
local Value = 1234
print("Human:", buffer.tostring(Serializer:Serialize(Value, "Human")))
print("Byte:", Serializer:Deserialize(Serializer:Serialize(Value, "Byte"), "Byte"))
print("Bit:", Serializer:Deserialize(Serializer:Serialize(Value, "Bit"), "Bit")) ]]

local Serializer = TypeGuard.Instance()
Serializer:Deserialize(Serializer:Serialize(workspace.SpawnLocation, "Bit"), "Bit").Parent = workspace