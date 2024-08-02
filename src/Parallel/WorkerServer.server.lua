local Actor = script:GetActor()
if (not Actor) then
    return
end

local Functions = (require :: any)(script:FindFirstChild("Functions"))

Actor:BindToMessageParallel("Run", function(FunctionID: string, ...)
    return Functions[FunctionID](...)
end)

Actor:BindToMessageParallel("RunPiped", function(FunctionID: string, Event: BindableEvent, ...)
    Event:Fire(Functions[FunctionID](...))
end)