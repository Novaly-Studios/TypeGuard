--!native
--!optimize 2

if (not script) then
    script = game:GetService("ReplicatedFirst").TypeGuard.Roblox.Any
end

local Core = script.Parent.Parent.Core
    local Function = require(Core.Function)
    local Boolean = require(Core.Boolean)
    local Number = require(Core.Number)
    local String = require(Core.String)
    local Object = require(Core.Object)
    local Thread = require(Core.Thread)
    local Array = require(Core.Array)
    local Nil = require(Core.Nil)
    local Or = require(Core.Or)

local Roblox = script.Parent
    local _CFrame = require(Roblox.CFrame)
    local _Color3 = require(Roblox.Color3)
    local _ColorSequence = require(Roblox.ColorSequence)
    local _ColorSequenceKeypoint = require(Roblox.ColorSequenceKeypoint)
    local _Enum = require(Roblox.Enum)
    local _Instance = require(Roblox.Instance)
    local _NumberSequence = require(Roblox.NumberSequence)
    local _NumberSequenceKeypoint = require(Roblox.NumberSequenceKeypoint)
    local _UDim = require(Roblox.UDim)
    local _UDim2 = require(Roblox.UDim2)
    local _Vector2 = require(Roblox.Vector2)
    local _Vector3 = require(Roblox.Vector3)
    local _TweenInfo = require(Roblox.TweenInfo)

local UInt8 = Number():Integer(8, true)
local Int8 = Number():Integer(8, false)
local UInt16 = Number():Integer(16, true)
local Int16 = Number():Integer(16, false)
local UInt32 = Number():Integer(32, true)
local Int32 = Number():Integer(32, false)
local Float32 = Number():Float(32)
local Float64 = Number():Float(64)
local DefaultFunction = Function()
local DefaultBoolean = Boolean()
local DefaultString = String()
local DefaultThread = Thread()
local DefaultNil = Nil()
local DefaultCFrame = _CFrame()
local DefaultColor3 = _Color3()
local DefaultVector3 = _Vector3()
-- local DefaultInstance = _Instance()
local DefaultVector2 = _Vector2()
local DefaultUDim2 = _UDim2()
local DefaultEnum = _Enum()
local DefaultUDim = _UDim()
local DefaultColorSequenceKeypoint = _ColorSequenceKeypoint()
local DefaultColorSequence = _ColorSequence()
local DefaultNumberSequenceKeypoint = _NumberSequenceKeypoint()
local DefaultNumberSequence = _NumberSequence()
local DefaultTweenInfo = _TweenInfo()

local Types = {
    UInt8;
    Int8;
    UInt16;
    Int16;
    UInt32;
    Int32;
    Float32;
    Float64;
    DefaultFunction;
    DefaultBoolean;
    DefaultString;
    DefaultThread;
    DefaultNil;
    DefaultCFrame;
    DefaultColor3;
    DefaultVector3;
            -- DefaultInstance;
    DefaultVector2;
    DefaultUDim2;
    DefaultEnum;
    DefaultUDim;
    DefaultColorSequenceKeypoint;
    DefaultColorSequence;
    DefaultNumberSequenceKeypoint;
    DefaultNumberSequence;
    DefaultTweenInfo;
}

local TypeToIndex = {}
for Index, Type in Types do
    for _, TypeOf in Type._TypeOf do
        TypeToIndex[TypeOf] = Index
    end
end

local DefaultObjectIndex
local DefaultArrayIndex
local UInt8Index = table.find(Types, UInt8)
local Int8Index = table.find(Types, Int8)
local UInt16Index = table.find(Types, UInt16)
local Int16Index = table.find(Types, Int16)
local UInt32Index = table.find(Types, UInt32)
local Int32Index = table.find(Types, Int32)
local Float32Index = table.find(Types, Float32)
local Float64Index = table.find(Types, Float64)

local Any = Or(unpack(Types)):DefineGetType(function(Value)
    local ValueType = typeof(Value)
    if (ValueType == "number") then
        return UInt8:Check(Value) and UInt8Index or
                Int8:Check(Value) and Int8Index or
                UInt16:Check(Value) and UInt16Index or
                Int16:Check(Value) and Int16Index or
                UInt32:Check(Value) and UInt32Index or
                Int32:Check(Value) and Int32Index or
                Float32:Check(Value) and Float32Index or
                Float64:Check(Value) and Float64Index or
                error(`Number cannot be represented: {Value}`)
    end

    if (ValueType == "table") then
        if (Value[1] == nil) then
            return DefaultObjectIndex
        end
        return DefaultArrayIndex
    end

    local Index = TypeToIndex[ValueType]
    if (Index) then
        return Index
    end
    error(`Unhandled type: {ValueType}`)
end)

local Versions = {Any}
return function(Version: number, Applier: ((typeof(Any)) -> (typeof(Any)))?)
    local Copy = table.clone(Versions[Version])
    if (not Copy) then
        error(`Unknown RbxAny serialization version: {Version}`)
    end

    -- Apply any changes here.
    if (Applier) then
        Copy = Applier(Copy)
    end

    -- Then self-reference that potentially modified copy.
    local IsATypeIn = Copy:GetConstraint("IsATypeIn")[1]
    local DefaultArray = Array(Copy)
    table.insert(IsATypeIn, DefaultArray)
    DefaultArrayIndex = table.find(IsATypeIn, DefaultArray)
    local DefaultObject = Object():OfKeyType(Copy):OfValueType(Copy)
    table.insert(IsATypeIn, DefaultObject)
    DefaultObjectIndex = table.find(IsATypeIn, DefaultObject)
    Copy:_Changed()
    return Copy
end