--!native
--!optimize 2

if (not script and Instance) then
    script = game:GetService("ReplicatedFirst").TypeGuard.Roblox.Any
end

local AnyConstructor = require(script.Parent.Parent.Core._AnyConstructor)

local Core = script.Parent.Parent.Core
    local Cacheable = require(Core.Cacheable)
    local Function = require(Core.Function)
    local Userdata = require(Core.Userdata)
    local Boolean = require(Core.Boolean)
    local Number = require(Core.Number)
    local String = require(Core.String)
    local Thread = require(Core.Thread)
    local Buffer = require(Core.Buffer)

local Roblox = script.Parent
    local RbxBrickColor = require(Roblox.BrickColor)
        local DefaultBrickColor = RbxBrickColor()
    local RbxCFrame = require(Roblox.CFrame)
        local DefaultCFrame = RbxCFrame():Compressed(1024)
    local RbxColor3 = require(Roblox.Color3)
        local DefaultColor3 = RbxColor3()
    local RbxColorSequence = require(Roblox.ColorSequence)
        local DefaultColorSequence = RbxColorSequence()
    local RbxColorSequenceKeypoint = require(Roblox.ColorSequenceKeypoint)
        local DefaultColorSequenceKeypoint = RbxColorSequenceKeypoint()
    local RbxEnum = require(Roblox.Enum)
        local DefaultEnum = RbxEnum()
    local RbxInstance = require(Roblox.Instance)
        local CacheableInstance = Cacheable(RbxInstance())
    local RbxNumberSequence = require(Roblox.NumberSequence)
        local DefaultNumberSequence = RbxNumberSequence()
    local RbxNumberSequenceKeypoint = require(Roblox.NumberSequenceKeypoint)
        local DefaultNumberSequenceKeypoint = RbxNumberSequenceKeypoint()
    local RbxRay = require(Roblox.Ray)
        local DefaultRay = RbxRay()
    local RbxTweenInfo = require(Roblox.TweenInfo)
        local DefaultTweenInfo = RbxTweenInfo()
    local RbxUDim = require(Roblox.UDim)
        local DefaultUDim = RbxUDim()
    local RbxUDim2 = require(Roblox.UDim2)
        local DefaultUDim2 = RbxUDim2()
    local RbxVector2 = require(Roblox.Vector2)
        local DefaultVector2 = RbxVector2()
    local RbxVector3 = require(Roblox.Vector3)
        local DefaultVector3 = RbxVector3()
    local RbxNumberRange = require(Roblox.NumberRange)
        local DefaultNumberRange = RbxNumberRange()
    local RbxAxes = require(Roblox.Axes)
        local DefaultAxes = RbxAxes()
    local RbxCatalogSearchParams = require(Roblox.CatalogSearchParams)
        local DefaultCatalogSearchParams = RbxCatalogSearchParams()
    local RbxContent = require(Roblox.Content)
        local DefaultContent = RbxContent()
    local RbxDateTime = require(Roblox.DateTime)
        local DefaultDateTime = RbxDateTime()
    local RbxFaces = require(Roblox.Faces)
        local DefaultFaces = RbxFaces()
    local RbxFloatCurveKey = require(Roblox.FloatCurveKey)
        local DefaultFloatCurveKey = RbxFloatCurveKey()
    local RbxFont = require(Roblox.Font)
        local DefaultFont = RbxFont()
    local RbxOverlapParams = require(Roblox.OverlapParams)
        local DefaultOverlapParams = RbxOverlapParams()
    local RbxPath2DControlPoint = require(Roblox.Path2DControlPoint)
        local DefaultPath2DControlPoint = RbxPath2DControlPoint()
    local RbxPathWaypoint = require(Roblox.PathWaypoint)
        local DefaultPathWaypoint = RbxPathWaypoint()
    local RbxPhysicalProperties = require(Roblox.PhysicalProperties)
        local DefaultPhysicalProperties = RbxPhysicalProperties()
    local RbxRaycastParams = require(Roblox.RaycastParams)
        local DefaultRaycastParams = RbxRaycastParams()
    local RbxRect = require(Roblox.Rect)
        local DefaultRect = RbxRect()
    local RbxRegion3 = require(Roblox.Region3)
        local DefaultRegion3 = RbxRegion3()
    local RbxRotationCurveKey = require(Roblox.RotationCurveKey)
        local DefaultRotationCurveKey = RbxRotationCurveKey()

local UInt8 = Number():Integer(8, false)
local NUInt8 = UInt8:Negative()
local UInt16 = Number():Integer(16, false)
local NUInt16 = UInt16:Negative()
local UInt32 = Number():Integer(32, false)
local NUInt32 = UInt32:Negative()
local Float32 = Number():Float(32)
local Float = Number()
local DefaultFunction = Function()
local DefaultUserdata = Userdata()
local DefaultBoolean = Boolean()
local CacheableString = Cacheable(String())
local DefaultThread = Thread()
local DefaultBuffer = Buffer()

local Types = {
    -- Numbers
    UInt8;
    NUInt8;
    UInt16;
    NUInt16;
    UInt32;
    NUInt32;
    Float32;
    Float;

    -- Common Strings
    CacheableString;

    -- Misc
    DefaultBoolean;
    DefaultBuffer;

    -- Roblox Types
    DefaultCFrame;
    DefaultColor3;
    DefaultColorSequence;
    DefaultColorSequenceKeypoint;
    DefaultEnum;
    CacheableInstance;
    DefaultNumberSequence;
    DefaultNumberSequenceKeypoint;
    DefaultRay;
    DefaultTweenInfo;
    DefaultUDim;
    DefaultUDim2;
    DefaultVector2;
    DefaultVector3;
    DefaultBrickColor;
    DefaultNumberRange;
    DefaultAxes;
    DefaultCatalogSearchParams;
    DefaultContent;
    DefaultDateTime;
    DefaultFaces;
    DefaultFloatCurveKey;
    DefaultFont;
    DefaultOverlapParams;
    DefaultPath2DControlPoint;
    DefaultPathWaypoint;
    DefaultPhysicalProperties;
    DefaultRaycastParams;
    DefaultRect;
    DefaultRegion3;
    DefaultRotationCurveKey;

    -- Unserializable
    DefaultFunction;
    DefaultUserdata;
    DefaultThread;
}

local UInt8Index = table.find(Types, UInt8)
local NUInt8Index = table.find(Types, NUInt8)
local UInt16Index = table.find(Types, UInt16)
local NUInt16Index = table.find(Types, NUInt16)
local UInt32Index = table.find(Types, UInt32)
local NUInt32Index = table.find(Types, NUInt32)
local Float32Index = table.find(Types, Float32)
local FloatIndex = table.find(Types, Float)

local function GetType(Value: any, ValueType: string): number?
    if (ValueType == "number") then
        if (Value % 1 == 0) then
            if (Value < 0) then
                if (Value > -0x101) then
                    return NUInt8Index
                end
    
                if (Value > -0x10001) then
                    return NUInt16Index
                end
    
                if (Value > -0x100000001) then
                    return NUInt32Index
                end
    
                -- Not Float32 because that only stays stable up to -2^24 and this check is already at -2^32.
                return FloatIndex
            end

            if (Value < 0x100) then
                return UInt8Index
            end

            if (Value < 0x10000) then
                return UInt16Index
            end

            if (Value < 0x100000000) then
                return UInt32Index
            end

            return FloatIndex
        end

        if (Value > 3.402823466e+38) then
            return FloatIndex
        end

        return Float32Index
    end

    return nil
end

return AnyConstructor(Types, GetType, "Any")