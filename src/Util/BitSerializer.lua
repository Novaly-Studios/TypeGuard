--!optimize 2
--!native

if (not script) then
    script = game:GetService("ReplicatedFirst").TypeGuard.Util.BitSerializer
end

local bwritebits = buffer.writebits
local breadbits = buffer.readbits
local btostring = buffer.tostring
local bwriteu32 = buffer.writeu32
local bwritef32 = buffer.writef32
local bwritef64 = buffer.writef64
local bwriteu8 = buffer.writeu8
local breadu32 = buffer.readu32
local breadf32 = buffer.readf32
local breadf64 = buffer.readf64
local breadu8 = buffer.readu8
local bcreate = buffer.create
local bcopy = buffer.copy
local blen = buffer.len

local b32replace = bit32.replace
local b32extract = bit32.extract
local b32lshift = bit32.lshift
local b32band = bit32.band

local mceil = math.ceil
local mlog = math.log
local mmin = math.min

local sbyte = string.byte

local SampleBuffer = bcreate(8) -- This is used to capture the raw binary output of Luau's fast implementation of buffer write functions.

local DEFAULT_MIN_SIZE = 16

--- Abstracts over buffers with an auto-resize mechanism. All lengths are
--- represented in bits as a standard to allow forward-compatible switches
--- between byte-level and bit-level buffers. Intended for long duration
--- lifetime.
local function BitSerializer(Buffer: buffer?, Size: number?, ReadOnly: boolean?)
    Size = Size or (Buffer and blen(Buffer :: buffer)) or DEFAULT_MIN_SIZE -- Size represented in bytes.
    Buffer = Buffer or bcreate(Size :: number)

    -- Position represented in bits.
    local Position = 0

    --- Only works for up to 32 bits at a time. No assertion for performance.
    --- Same as ReadBits.
    local function WriteBits(Amount: number, Value: number)
        local NewPosition = Position + Amount
        local NewPositionBytes = mceil(NewPosition / 8)

        if (NewPositionBytes >= Size) then
            Size = 2 ^ mceil(mlog(NewPositionBytes, 2))
            local NewBuffer = bcreate(Size)
            bcopy(NewBuffer, 0, Buffer :: buffer)
            Buffer = NewBuffer
        end

        bwritebits(Buffer :: buffer, Position, Amount, Value)
        Position = NewPosition
    end

    local function ReadBits(Amount: number): number
        local Bits = breadbits(Buffer :: buffer, Position, Amount)
        Position += Amount
        return Bits
    end

    local function GetClippedBuffer(): buffer
        local SizeBytes = math.ceil(Position / 8)
        local New = bcreate(SizeBytes)
        bcopy(New, 0, Buffer :: any, 0, SizeBytes)
        return New
    end

    --[[ local function GetChunks(ChunkSize: number): {buffer}
        -- Todo. Useful for unreliable events data splitting.
        error("Unimplemented")
    end ]]

    local Result = {
        --[[ WriteUInt = function(...)
            print("WU", ...)
            WriteBits(...)
        end;
        ReadUInt = function(...)
            local Value = ReadBits(...)
            print("RU", ..., "=", Value)
            return Value
        end; ]]
        WriteUInt = WriteBits;
        ReadUInt = ReadBits;
        WriteInt = function(Bits: number, Value: number)
            -- print("WI", Bits, Value)
            if (Value >= 0) then
                WriteBits(Bits, Value)
                return
            end

            -- Negative -> apply two's complement.
            WriteBits(Bits, Value + b32lshift(1, Bits))
        end;
        ReadInt = function(Bits: number): number
            local Value = ReadBits(Bits)

            if (b32extract(Value, Bits - 1) == 1) then
                -- print("RI", Bits, "=", Value - b32lshift(1, Bits))
                return Value - b32lshift(1, Bits)
            end

            -- print("RI", Bits, "=", Value)
            return Value
        end;
        WriteFloat = function(Bits: number, Value: number)
            -- print("WF", Bits, Value)
            -- This will support non-standard precision floats in the future (like 21 bits or 16 bits, and custom exponent length).
            if (Bits > 32) then
                bwritef64(SampleBuffer, 0, Value)
                WriteBits(32, breadu32(SampleBuffer, 0))
                WriteBits(32, breadu32(SampleBuffer, 4))
                return
            end

            bwritef32(SampleBuffer, 0, Value)
            WriteBits(32, breadu32(SampleBuffer, 0))
        end;
        ReadFloat = function(Bits: number): number
            -- We'll support non standard precision floats in the future.
            if (Bits > 32) then
                bwriteu32(SampleBuffer, 0, ReadBits(32))
                bwriteu32(SampleBuffer, 4, ReadBits(32))
                -- print("RF64", Bits, "=", breadf64(SampleBuffer, 0))
                return breadf64(SampleBuffer, 0)
            end

            -- print("RF32(1)", Position, buffer.len(Buffer) * 8)
            bwriteu32(SampleBuffer, 0, ReadBits(32))
            -- print("RF32", Bits, "=", breadf32(SampleBuffer, 0))
            return breadf32(SampleBuffer, 0)
        end;
        WriteString = function(String: string, Length: number)
            -- print("WS", String)
            local Bytes = Length // 8
            local FinalBits = b32band(Length, 7)

            for Index = 1, Bytes, 4 do
                local Char1, Char2, Char3, Char4 = sbyte(String, Index, Index + 3)

                -- We have a block of 4 or 3 or 2, we can write as multiple combined values at once which is faster.
                if (Char4) then
                    WriteBits(32, b32lshift(Char4, 24) + b32lshift(Char3, 16) + b32lshift(Char2, 8) + Char1)
                    continue
                end

                if (Char3) then
                    WriteBits(24, b32lshift(Char3, 16) + b32lshift(Char2, 8) + Char1)
                    continue
                end

                if (Char2) then
                    WriteBits(16, b32lshift(Char2, 8) + Char1)
                    continue
                end

                WriteBits(8, Char1)
            end

            if (FinalBits > 0) then
                WriteBits(FinalBits, sbyte(String, Bytes + 1))
            end
        end;
        ReadString = function(Length: number): string
            local Bytes = Length // 8
            local FinalBits = (Length and b32band(Length, 7) or 0)

            local HasMore = (FinalBits > 0)
            local Result = bcreate(Bytes + (HasMore and 1 or 0))
            local To = Bytes - b32band(Bytes, 3) -- Move to nearest multiple of 4.

            -- Write string as chunks of 32 bits.
            for Index = 0, To - 1, 4 do
                bwriteu32(Result, Index, ReadBits(32))
            end

            -- Write remaining string as chunks of 8 bits.
            for Index = To, Bytes - 1 do
                bwriteu8(Result, Index, ReadBits(8))
            end

            -- Write final part of string as bits.
            if (HasMore) then
                bwriteu8(Result, Bytes, ReadBits(FinalBits))
            end

            -- print("RS(2)", Bytes, "=", btostring(Result))
            return btostring(Result)
        end;
        SetPosition = function(Bit: number)
            Position = Bit
        end;
        GetPosition = function()
            return Position
        end;
        GetBuffer = function()
            return Buffer :: buffer
        end;
        GetClippedBuffer = GetClippedBuffer;
    }

    --[[ for Key, Value in Result do
        Result[Key] = function(...)
            debug.profilebegin(Key)
            local Result = Value(...)
            debug.profileend()
            return Result
        end
    end ]]

    return Result
end

--[[ local Test = BitSerializer()

Test.WriteUInt(1, 0b0)
Test.WriteUInt(17, 0b11111111111111111)
Test.WriteUInt(2, 0b10)
Test.WriteFloat(64, 1.2)
Test.WriteString("Mraow", 8 * 5)
Test.WriteInt(8, -128)
Test.WriteString("AHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHH", 8 * 38)

Test.SetPosition(0)

print(Test.ReadUInt(1))
print(Test.ReadUInt(17))
print(Test.ReadUInt(2))
print(Test.ReadFloat(64))
print(Test.ReadString(8 * 5))
print(Test.ReadInt(8))
print(Test.ReadString(0))
print(Test.ReadString(8 * 38)) ]]

return BitSerializer