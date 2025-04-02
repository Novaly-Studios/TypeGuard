local TypeGuard = require(script.Parent.Parent)
local Roblox = require(script.Parent.Roblox)

local Test = Roblox.new("Test", TypeGuard.Any())

Test:OnReceive(function(...)
    -- print("Server received:", ...)
    print("----------------", ...)
end)