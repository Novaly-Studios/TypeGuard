--!optimize 2
--!native

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

--[[ local BaseAny = require(game.ReplicatedFirst.TypeGuard.Core.BaseAny)
print(BaseAny:Deserialize(BaseAny:Serialize(Test, "Bit", false), "Bit", false)) ]]

--[[ local Any = require(game.ReplicatedFirst.TypeGuard.Roblox.Any)
print(Any:Deserialize(Any:Serialize(Test, "Byte", false), "Byte", false)) ]]

--[[ local Any = require(game.ReplicatedFirst.TypeGuard.Roblox.Any)
print(Any:Check({false, buffer.create(10)})) ]]