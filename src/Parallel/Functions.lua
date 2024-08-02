local ReplicatedStorage = game:GetService("ReplicatedStorage")
    local ParallelFunctions = ReplicatedStorage:FindFirstChild("ParallelFunctions")

local Functions = {}

if (not ParallelFunctions) then
    ParallelFunctions = Instance.new("Folder")
    ParallelFunctions.Name = "ParallelFunctions"
    ParallelFunctions.Parent = ReplicatedStorage
end

local function RegisterFunction(Child)
    if (string.sub(Child.Name, 1, 1) == "_" or not Child:IsA("ModuleScript")) then
        return
    end
    Functions[Child.Name] = require(Child)
end

for _, Child in ParallelFunctions:GetChildren() do
    RegisterFunction(Child)
end
ParallelFunctions.ChildAdded:Connect(RegisterFunction)

function Functions._ADD_MODULE(ID: string, Module: ModuleScript)
    local Existing = ParallelFunctions:FindFirstChild(ID)
    if (Existing) then
        Existing:Destroy()
    end

    local Copy = Module:Clone()
    Copy.Name = ID
    Copy.Parent = ParallelFunctions
end

return Functions