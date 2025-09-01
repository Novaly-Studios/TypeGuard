--!optimize 2
--!native

if (not script and Instance) then
    script = game:GetService("ReplicatedFirst").TypeGuard.Util.BitSerializer
end

local Types = require(script.Parent._Types)

local bufwritestring = buffer.writestring
local bufreadstring = buffer.readstring
local bufwritebits = buffer.writebits
local bufreadbits = buffer.readbits
local buftostring = buffer.tostring
local bufwriteu32 = buffer.writeu32
local bufwritef32 = buffer.writef32
local bufwritef64 = buffer.writef64
local bufwriteu8 = buffer.writeu8
local bufreadu32 = buffer.readu32
local bufreadf32 = buffer.readf32
local bufreadf64 = buffer.readf64
local bufcreate = buffer.create
local bufcopy = buffer.copy
local buflen = buffer.len

local b32extract = bit32.extract
local b32lshift = bit32.lshift
local b32band = bit32.band

local dbginfo = debug.info

local mthceil = math.ceil
local mthmin = math.min
local mthlog = math.log

local strbyte = string.byte

local SampleBuffer = bufcreate(8) -- This is used to capture the raw binary output of Luau's (faster) implementation of buffer write functions.

local DEFAULT_MIN_SIZE = 16

--- Abstracts over buffers with an auto-resize mechanism. All lengths are
--- represented in bits as a standard to allow forward-compatible switches
--- between byte-level and bit-level buffers. Intended for long duration
--- lifetime.
local BitSerializer: Types.SerializerConstructor = function(Buffer, Size, ProfilerTags)
    Size = Size or (Buffer and buflen(Buffer)) or DEFAULT_MIN_SIZE -- Size represented in bytes.
    Buffer = Buffer or bufcreate(Size)

    -- Position represented in bits.
    local Position = 0

    local function CheckResize(AdditionalBits)
        local Sum = Position + AdditionalBits
        local AsBytes = mthceil(Sum / 8)

        if (AsBytes >= Size) then
            Size = 2 ^ mthceil(mthlog(AsBytes, 2))
            local NewBuffer = bufcreate(Size)
            bufcopy(NewBuffer, 0, Buffer)
            Buffer = NewBuffer
        end

        return Sum
    end

    local function WriteBits(Bits, Value)
        if (Bits == 0) then
            return
        end

        local NewPosition = CheckResize(Bits)
        bufwritebits(Buffer, Position, Bits, Value)
        Position = NewPosition
    end

    local function ReadBits(Bits)
        if (Bits == 0) then
            return 0
        end

        local Result = bufreadbits(Buffer, Position, Bits)
        Position += Bits
        return Result
    end


    --[[ local function GetChunks(ChunkSize)
        -- Todo. Useful for unreliable events data splitting.
        error("Unimplemented")
    end ]]

    local Result: Types.Serializer = {
        WriteUInt = WriteBits;
        ReadUInt = ReadBits;

        WriteInt = function(Bits, Value)
            if (Bits == 0) then
                return
            end

            if (Value < 0) then
                Value += b32lshift(1, Bits - 1) * 2
            end

            WriteBits(Bits, Value)
        end;
        ReadInt = function(Bits)
            if (Bits == 0) then
                return 0
            end

            local Value = ReadBits(Bits)
            Bits -= 1

            if (b32extract(Value, Bits) == 1) then
                Value -= b32lshift(1, Bits) * 2
            end

            return Value
        end;

        WriteFloat = function(Bits, Value)
            if (Bits == 0) then
                return
            end

            -- This will support non-standard precision floats in the future (like 21 bits or 16 bits, and custom exponent length).
            if (Bits > 32) then
                bufwritef64(SampleBuffer, 0, Value)
                WriteBits(32, bufreadu32(SampleBuffer, 0))
                WriteBits(32, bufreadu32(SampleBuffer, 4))
                return
            end

            bufwritef32(SampleBuffer, 0, Value)
            WriteBits(32, bufreadu32(SampleBuffer, 0))
        end;
        ReadFloat = function(Bits)
            if (Bits == 0) then
                return 0
            end

            -- We'll support non standard precision floats in the future.
            if (Bits > 32) then
                bufwriteu32(SampleBuffer, 0, ReadBits(32))
                bufwriteu32(SampleBuffer, 4, ReadBits(32))
                return bufreadf64(SampleBuffer, 0)
            end

            bufwriteu32(SampleBuffer, 0, ReadBits(32))
            return bufreadf32(SampleBuffer, 0)
        end;

        WriteBuffer = function(Bits, Subject, From)
            if (Bits == 0) then
                return
            end

            -- Buffer is byte-aligned from start to end, copy it directly using inbuilt copy (faster).
            -- BitSerializer only does this for writes which are generally large (buffer, string) as it
            -- would otherwise be slower for realistic usages.
            if (Position % 8 == 0 and Bits % 8 == 0 and From % 8 == 0) then
                local NewPosition = CheckResize(Bits)
                bufcopy(Buffer, Position // 8, Subject, From // 8, Bits // 8)
                Position = NewPosition
                return
            end

            local Accumulation = 0

            while (Accumulation < Bits) do
                local ToWrite = mthmin(32, Bits - Accumulation)
                WriteBits(ToWrite, bufreadbits(Subject, From + Accumulation, ToWrite))
                Accumulation += ToWrite
            end
        end;
        ReadBuffer = function(Bits)
            if (Bits == 0) then
                return bufcreate(0)
            end

            if (Position % 8 == 0 and Bits % 8 == 0) then
                local Bytes = Bits // 8
                local Temp = bufcreate(Bytes)
                local NewPosition = CheckResize(Bits)
                bufcopy(Temp, 0, Buffer, Position // 8, Bytes)
                Position = NewPosition
                return Temp
            end

            local Accumulation = 0
            local Result = bufcreate(mthceil(Bits / 8))

            while (Accumulation < Bits) do
                local ToRead = mthmin(32, Bits - Accumulation)
                bufwritebits(Result, Accumulation, ToRead, ReadBits(ToRead))
                Accumulation += ToRead
            end

            return Result
        end;

        WriteString = function(String, Bits)
            if (Bits == 0) then
                return
            end

            if (Position % 8 == 0 and Bits % 8 == 0) then
                local NewPosition = CheckResize(Bits)
                bufwritestring(Buffer, Position // 8, String)
                Position = NewPosition
                return
            end

            local Bytes = Bits // 8
            local FinalBits = b32band(Bits, 7)

            for Index = 1, Bytes, 4 do
                local Char1, Char2, Char3, Char4 = strbyte(String, Index, Index + 3)

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
                WriteBits(FinalBits, strbyte(String, Bytes + 1))
            end
        end;
        ReadString = function(Bits)
            if (Bits == 0) then
                return ""
            end

            if (Position % 8 == 0 and Bits % 8 == 0) then
                local NewPosition = CheckResize(Bits)
                local Result = bufreadstring(Buffer, Position // 8, Bits // 8)
                Position = NewPosition
                return Result
            end

            local Bytes = Bits // 8
            local FinalBits = (Bits and b32band(Bits, 7) or 0)

            local HasMore = (FinalBits > 0)
            local Result = bufcreate(Bytes + (HasMore and 1 or 0))
            local To = Bytes - b32band(Bytes, 3) -- Move to nearest multiple of 4.

            -- Write string as chunks of 32 bits.
            for Index = 0, To - 1, 4 do
                bufwriteu32(Result, Index, ReadBits(32))
            end

            -- Write remaining string as chunks of 8 bits.
            for Index = To, Bytes - 1 do
                bufwriteu8(Result, Index, ReadBits(8))
            end

            -- Write final part of string as bits.
            if (HasMore) then
                bufwriteu8(Result, Bytes, ReadBits(FinalBits))
            end

            return buftostring(Result)
        end;

        IncrementPosition = function(Bits)
            Position += Bits
        end;
        SetPosition = function(Bit)
            Position = Bit
        end;
        GetPosition = function()
            return Position
        end;
        Extend = CheckResize;
        Align = function()
            Position += (8 - Position) % 8
        end;

        GetClippedBuffer = function()
            local SizeBytes = mthceil(Position / 8)
            local New = bufcreate(SizeBytes)
            bufcopy(New, 0, Buffer, 0, SizeBytes)
            return New
        end;
        GetBuffer = function()
            return Buffer
        end;
        SetBuffer = function(NewBuffer)
            Buffer = NewBuffer or bufcreate(DEFAULT_MIN_SIZE)
            Size = buflen(Buffer)
        end;

        Constructor = dbginfo(1, "f");
        Type = "Bit";
    }

    if (ProfilerTags and debug) then
        local dbgprofilebegin = debug.profilebegin
        local dbgprofileend = debug.profileend

        Result.Context = function(Name: string?)
            if (Name == nil) then
                dbgprofileend()
                return
            end

            dbgprofilebegin(Name)
        end
    end

    return Result
end

return BitSerializer