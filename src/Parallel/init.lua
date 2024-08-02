-- Small prototype for using Parallel Luau more easily, but still a bit rough around the edges.

local ServerScriptService = game:GetService("ServerScriptService")
local ReplicatedFirst = game:GetService("ReplicatedFirst")
local RunService = game:GetService("RunService")

local ACTOR_COUNT = 24

local ServerWorker = script:WaitForChild("WorkerServer")
local ClientWorker = script:WaitForChild("WorkerClient")
local FunctionsModule = script:WaitForChild("Functions")
    local ReqiuredFunctionsModule = require(FunctionsModule)

local RandomGen = Random.new()

local Parallel = {}

--[=[
    Well, they need to be stored somewhere, right?
]=]--
local function GetActorLocation()
    local Service = RunService:IsServer() and ServerScriptService or ReplicatedFirst
    local WorkerTemplate = RunService:IsServer() and ServerWorker or ClientWorker

    local Folder = Service:FindFirstChild("ParallelActors")

    if (not Folder) then
        Folder = Instance.new("Folder")
        Folder.Name = "ParallelActors"
        Folder.Parent = Service

        for Index = 1, ACTOR_COUNT do
            local Actor = Instance.new("Actor")

            local Worker = WorkerTemplate:Clone()
            Worker.Parent = Actor

            local WorkerFunctions = FunctionsModule:Clone()
            WorkerFunctions.Parent = Worker

            Actor.Parent = Folder
        end
    end

    return Folder
end
GetActorLocation()

--[=[
    Call a function on a random actor.

    @param FunctionID string The name of the function to call, must be in the Functions folder.
    @return nil
]=]--
function Parallel.Run(FunctionID: string, ...)
    assert(typeof(FunctionID) == "string", "Expected string for arg #1")

    local ActorLocation = GetActorLocation()
    local ChosenActor: Actor = ActorLocation:GetChildren()[RandomGen:NextInteger(1, ACTOR_COUNT)]

    ChosenActor:SendMessage("Run", FunctionID, ...)
end

--[=[
    Call a function on a random actor, and pipe the results to a BindableEvent.

    @param FunctionID string The name of the function to call, must be in the Functions folder.
    @param Event BindableEvent The event to fire when the function returns.
    @return nil
]=]--
function Parallel.RunPiped(FunctionID: string, Event: BindableEvent, ...)
    local ActorLocation = GetActorLocation()
    local ChosenActor: Actor = ActorLocation:GetChildren()[RandomGen:NextInteger(1, ACTOR_COUNT)]
    ChosenActor:SendMessage("RunPiped", FunctionID, Event, ...)
end

--[=[
    Call a function on a random actor, and wait for the result.

    @param FunctionID string The name of the function to call, must be in the Functions folder.
    @return any
]=]--
function Parallel.Await(FunctionID: string, ...)
    local BindableEvent = Instance.new("BindableEvent")
    Parallel.RunPiped(FunctionID, BindableEvent, ...)
    return BindableEvent.Event:Wait()
end

--[=[
    Add a function to the ParallelFunctions folder.

    @param ID string The name of the function.
    @param Module ModuleScript The module script to add.
    @return nil
]=]--
function Parallel.AddFunction(ID: string, Module: ModuleScript)
    ReqiuredFunctionsModule._ADD_MODULE(ID, Module)
end

return Parallel