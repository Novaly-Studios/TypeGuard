local ReplicatedStorage = game:GetService("ReplicatedStorage")

local RunService = game:GetService("RunService")
    local IsClient = RunService:IsClient()

local Players = game:GetService("Players")

local TypeGuard = require(script.Parent.Parent)

local ActivePlayers = {} do
    Players.PlayerAdded:Connect(function(Player)
        table.insert(ActivePlayers, Player)
    end)

    Players.PlayerRemoving:Connect(function(Player)
        table.remove(ActivePlayers, table.find(ActivePlayers, Player))
    end)
end

local CustomRemotes = ReplicatedStorage:FindFirstChild("CustomRemotes")

if (IsClient) then
    CustomRemotes = ReplicatedStorage:WaitForChild("CustomRemotes")
else
    CustomRemotes = Instance.new("Folder")
    CustomRemotes.Name = "CustomRemotes"
    CustomRemotes.Parent = ReplicatedStorage
end

local RemoteHooks = {}

local VALID_CACHE_TYPES = {
    string = function(Value)
        return #Value < 65
    end;
    Instance = function()
        return true;
    end;
}

local Net = {}
Net.__index = Net

function Net.new(RemoteID: string, Definition: TypeGuard.SignatureTypeChecker, SerializeType: ("Byte" | "Bit" | "Human")?)
    local RemoteEvent

    if (IsClient) then
        RemoteEvent = CustomRemotes:WaitForChild(RemoteID)
    else
        RemoteEvent = Instance.new("RemoteEvent")
        RemoteEvent.Name = RemoteID
        RemoteEvent.Parent = CustomRemotes
    end

    local self = setmetatable({
        _SerializeType = SerializeType or "Bit";
        _NodeToState = {};
        _RemoteEvent = RemoteEvent;
        _Definition = Definition;
        _RemoteID = RemoteID;
        _Hooks = {};
    }, Net)

    self._PlayerLeftConnection = Players.PlayerRemoving:Connect(function(Player)
        self._NodeToState[Player.Name] = nil
    end)

    self._RemoteConnection = (IsClient and RemoteEvent.OnClientEvent:Connect(function(Data, CacheDifferences)
        self:_ReceiveEvent(Data, self:_GetOrCreateNodeState("Server"), CacheDifferences)
    end) or RemoteEvent.OnServerEvent:Connect(function(Player, Data, CacheDifferences)
        local SenderID = Player.Name
        self:_ReceiveEvent(Data, self:_GetOrCreateNodeState(SenderID), CacheDifferences, SenderID)
    end))

    assert(RemoteHooks[RemoteID] == nil, `Remote ID {RemoteID} already exists`)
    RemoteHooks[RemoteID] = self
    return self
end

function Net:_ReceiveEvent(Data, SenderNodeState, CacheDifferences, SenderID)
    local InsertValue = SenderNodeState.InsertValue

    print(">>>>Cache Differences", CacheDifferences)
    for _, Value in CacheDifferences do
        InsertValue(Value, false)
    end
    print(">>>>State", SenderNodeState)

    Data = SenderNodeState.Definition:Deserialize(Data, self._SerializeType)

    if (IsClient) then
        for _, Callback in self._Hooks do
            task.spawn(Callback, SenderID, Data)
        end

        return
    end

    for _, Callback in self._Hooks do
        task.spawn(Callback, Data)
    end
end

function Net:_GetOrCreateNodeState(Recipient: string)
    local NodeToState = self._NodeToState
        local NodeState = NodeToState[Recipient]

    if (not NodeState) then
        local RotatingIndex = 0
        local CacheSize = 128

        local CacheDifferences = {}
        local ValueToIndex = {}
        local IndexToValue = {}

        local function InsertValue(Value, Origin)
            local Index = ValueToIndex[Value]

            if (Index) then
                return Index
            end

            Index = RotatingIndex + 1

            local OldValue = IndexToValue[Index]

            if (OldValue) then
                ValueToIndex[OldValue] = nil
            end

            IndexToValue[Index] = Value
            ValueToIndex[Value] = Index

            if (Origin) then
                table.insert(CacheDifferences, Value)
            end

            RotatingIndex = Index % CacheSize
            return Index
        end

        local function GetIndexFromValue(Value)
            local Validator = VALID_CACHE_TYPES[typeof(Value)]

            if (not Validator or not Validator(Value)) then
                return nil
            end

            local Index = ValueToIndex[Value]

            if (Index) then
                return Index
            end

            return InsertValue(Value, true)
        end

        local function GetValueFromIndex(Index)
            return IndexToValue[Index]
        end

        NodeState = {
            CacheDifferences = CacheDifferences;
            Definition = TypeGuard.ValueCache(self._Definition):PersistentCache(function(Value)
                return GetIndexFromValue(Value)
            end, function(Index)
                return GetValueFromIndex(Index)
            end);
            InsertValue = InsertValue;
        }
        NodeToState[Recipient] = NodeState
    end

    return NodeState
end

function Net:_SerializePackage(Data: any, Recipient: string): (buffer, any)
    local NodeState = self:_GetOrCreateNodeState(Recipient)
    local Result = NodeState.Definition:Serialize(Data, self._SerializeType)
    local CacheDifferences = table.clone(NodeState.CacheDifferences)
    table.clear(NodeState.CacheDifferences)
    return Result, CacheDifferences
end

function Net:FireAllClients(Data: any)
    for _, Player in ActivePlayers do
        self:FireClient(Player, Data)
    end
end

function Net:FireClient(Recipient: Player, Data: any)
    local Serialized, CacheDifferences = self:_SerializePackage(Data, Recipient.Name)
    self._RemoteEvent:FireClient(Recipient, Serialized, CacheDifferences)
end

function Net:FireServer(Data: any)
    local Serialized, CacheDifferences = self:_SerializePackage(Data, "Server")
    self._RemoteEvent:FireServer(Serialized, CacheDifferences)
end

function Net:OnReceive(Callback)
    local Hooks = self._Hooks
    table.insert(Hooks, Callback)

    return function()
        table.remove(Hooks, table.find(Hooks, Callback))
    end
end

function Net:Destroy()
    self._PlayerLeftConnection:Disconnect()
    self._RemoteConnection:Disconnect()
    RemoteHooks[self._RemoteID] = nil
end

return Net
