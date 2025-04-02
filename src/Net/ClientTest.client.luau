local TypeGuard = require(script.Parent.Parent)
local Roblox = require(script.Parent.Roblox)

local Test = Roblox.new("Test", TypeGuard.Any())

--[[ Test:OnReceive(function(...)
    print("Client received:", ...)
end) ]]

task.wait(1)

local Sets = {
    {Value = "One", Inst = workspace};
    {Value = "Two", Inst = workspace};
    {Value = "Three", Inst = workspace.SpawnLocation};
    {Value = "Four", Inst = workspace.SpawnLocation};
    {Value = "Five", Inst = workspace};
}

for Index = 1, 5 do
    Test:FireServer(Sets[Index])
    task.wait(1)
end