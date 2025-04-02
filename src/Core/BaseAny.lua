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

return AnyConstructor(Types, GetType, "BaseAny")