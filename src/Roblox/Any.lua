--!native
--!optimize 2

if (not script) then
    script = game:GetService("ReplicatedFirst").TypeGuard.Roblox.Any
end

local TableUtil = require(script.Parent.Parent.Parent.TableUtil).WithFeatures()
    local ArrayMerge = TableUtil.Array.Merge
    local MergeDeep = TableUtil.Map.MergeDeep

local Core = script.Parent.Parent.Core
    local Function = require(Core.Function)
    local Userdata = require(Core.Userdata)
    local Boolean = require(Core.Boolean)
    local Number = require(Core.Number)
    local String = require(Core.String)
    local Object = require(Core.Object)
    local Thread = require(Core.Thread)
    local Buffer = require(Core.Buffer)
    local Array = require(Core.Array)
    local Or = require(Core.Or)

local Roblox = script.Parent
    local RbxBrickColor = require(Roblox.BrickColor)
        local DefaultBrickColor = RbxBrickColor()
    local RbxCFrame = require(Roblox.CFrame)
        local DefaultCFrame = RbxCFrame()
    local RbxColor3 = require(Roblox.Color3)
        local DefaultColor3 = RbxColor3()
    local RbxColorSequence = require(Roblox.ColorSequence)
        local DefaultColorSequence = RbxColorSequence()
    local RbxColorSequenceKeypoint = require(Roblox.ColorSequenceKeypoint)
        local DefaultColorSequenceKeypoint = RbxColorSequenceKeypoint()
    local RbxEnum = require(Roblox.Enum)
        local DefaultEnum = RbxEnum()
    local RbxInstance = require(Roblox.Instance)
        local DefaultInstance = RbxInstance()
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

local UInt8 = Number():Integer(8, true)
local Int8 = Number():Integer(8, false)
local UInt16 = Number():Integer(16, true)
local Int16 = Number():Integer(16, false)
local UInt32 = Number():Integer(32, true)
local Int32 = Number():Integer(32, false)
local Float32 = Number():Float(32)
local Float = Number()
local DefaultFunction = Function()
local DefaultUserdata = Userdata()
local DefaultBoolean = Boolean()
local DefaultString = String()
local DefaultThread = Thread()
local DefaultBuffer = Buffer()

local Types = {
    -- Numbers
    UInt8;
    Int8;
    UInt16;
    Int16;
    UInt32;
    Int32;
    Float32;
    Float;

    -- Common Strings
    DefaultString;

    -- Misc
    DefaultBoolean;
    DefaultBuffer;

    -- Roblox Types
    DefaultCFrame;
    DefaultColor3;
    DefaultColorSequence;
    DefaultColorSequenceKeypoint;
    DefaultEnum;
    DefaultInstance;
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

local TypeToIndex = {}
for Index, Type in Types do
    --[[ Types[Index] = Type:_MapCheckers(function(Checker)
        if (Checker.Type ~= "Instance") then
            return Checker
        end

        return Checker:Reference("NetSync")
    end, true) ]]

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
local FloatIndex = table.find(Types, Float)

local Any = table.clone(Or(unpack(Types)):DefineGetType(function(Value)
    local ValueType = typeof(Value)

    if (ValueType == "number") then
        if (Value % 1 == 0) then
            if (Value >= 0) then
                if (Value <= 0xFF) then
                    return UInt8Index
                end

                if (Value <= 0xFFFF) then
                    return UInt16Index
                end

                if (Value <= 0xFFFFFFFF) then
                    return UInt32Index
                end

                error(`Unsigned integer cannot be represented: {Value}`)
            end

            if (Value >= -0x80) then
                return Int8Index
            end

            if (Value >= -0x8000) then
                return Int16Index
            end

            if (Value >= -0x80000000) then
                return Int32Index
            end

            error(`Signed integer cannot be represented: {Value}`)
        end

        if (Value <= 3.402823466e+38) then
            return Float32Index
        end

        return FloatIndex
    end

    if (ValueType == "table" or ValueType == "SharedTable") then
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
end))

-- Self-reference / recursive (object or array of type Any). Can't copy the root table.
local function Setup()
    if (Any._Setup) then
        return
    end
    Any._Setup = true

    local DefaultArray = Array(Any)
    local DefaultObject = Object():OfKeyType(Any):OfValueType(Any)
    local _, Index = Any:GetConstraint("IsATypeIn")
    Any._ActiveConstraints = MergeDeep(Any._ActiveConstraints, {
        [Index] = {
            Args = {
                [1] = function(ExistingArgs)
                    return ArrayMerge(ExistingArgs, {DefaultArray, DefaultObject})
                end;
            };
        };
    }, true)

    local IsATypeIn = Any._ActiveConstraints[Index].Args[1]
    DefaultArrayIndex = table.find(IsATypeIn, DefaultArray)
    DefaultObjectIndex = table.find(IsATypeIn, DefaultObject)
    Any:_UpdateSerializeFunctionCache()
    table.freeze(Any)
end

-- We wrap Serialize and Deserialize to avoid immediate cyclic requires. Some other modules
-- require BaseAny while BaseAny also requires them, we can instead run the require setup when
-- these functions are called.
local OriginalSerialize = Any.Serialize
Any.Serialize = function(...)
    Setup()
    return OriginalSerialize(...)
end

local OriginalDeserialize = Any.Deserialize
Any.Deserialize = function(...)
    Setup()
    return OriginalDeserialize(...)
end

-- Avoid recursive tostring weirdness.
local NewMT = table.clone(getmetatable(Any))
NewMT.__tostring = function()
    return "Any()"
end
setmetatable(Any, NewMT)

-- Disallow all constraints or functions which would copy the root, as that will break the self-reference to Any.
local AllowFunctions = {"Check", "Assert", "AsPredicate", "AsAssert", "Serialize", "Deserialize", "GetConstraint", "_Serialize", "_Deserialize", "_Check", "_Initial", "_UpdateSerializeFunctionCache"}
for Key, Value in Any do
    if (type(Value) ~= "function") then
        continue
    end

    if (table.find(AllowFunctions, Key)) then
        continue
    end

    Any[Key] = nil
end

return Any :: {
    Deserialize: ((Buffer: buffer, Cache: any?) -> (any));
    AsPredicate: (() -> ((Value: any) -> (boolean)));
    Serialize: ((Value: any, Atom: string?, BypassCheck: boolean?, Cache: any?) -> (buffer));
    AsAssert: (() -> ((Value: any) -> ()));
    Assert: ((Value: any) -> ());
    Check: ((Value: any) -> (boolean));
}