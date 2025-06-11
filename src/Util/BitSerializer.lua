--!optimize 2
--!native

if (not script) then
    script = game:GetService("ReplicatedFirst").TypeGuard.Util.BitSerializer
end

local bwritestring = buffer.writestring
local breadstring = buffer.readstring
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
local bcreate = buffer.create
local bcopy = buffer.copy
local blen = buffer.len

local b32extract = bit32.extract
local b32lshift = bit32.lshift
local b32band = bit32.band

local mceil = math.ceil
local mlog = math.log

local sbyte = string.byte

local SampleBuffer = bcreate(8) -- This is used to capture the raw binary output of Luau's (faster) implementation of buffer write functions.

local DEFAULT_MIN_SIZE = 16

--- Abstracts over buffers with an auto-resize mechanism. All lengths are
--- represented in bits as a standard to allow forward-compatible switches
--- between byte-level and bit-level buffers. Intended for long duration
--- lifetime.
local function BitSerializer(Buffer: buffer?, Size: number?)
    Size = Size or (Buffer and blen(Buffer :: buffer)) or DEFAULT_MIN_SIZE -- Size represented in bytes.
    Buffer = Buffer or bcreate(Size :: number)

    -- Position represented in bits.
    local Position = 0

    local function CheckResize(AdditionalBits: number)
        local Sum = Position + AdditionalBits
        local AsBytes = mceil(Sum / 8)

        if (AsBytes >= Size) then
            Size = 2 ^ mceil(mlog(AsBytes, 2))
            local NewBuffer = bcreate(Size)
            bcopy(NewBuffer, 0, Buffer :: buffer)
            Buffer = NewBuffer
        end

        return Sum
    end

    local function WriteBits(Bits: number, Value: number)
        if (Bits == 0) then
            return
        end

        local NewPosition = CheckResize(Bits)
        bwritebits(Buffer :: buffer, Position, Bits, Value)
        Position = NewPosition
    end

    local function ReadBits(Bits: number): number
        if (Bits == 0) then
            return 0
        end

        local Result = breadbits(Buffer :: buffer, Position, Bits)
        Position += Bits
        return Result
    end

    local function GetClippedBuffer(): buffer
        local SizeBytes = mceil(Position / 8)
        local New = bcreate(SizeBytes)
        bcopy(New, 0, Buffer :: any, 0, SizeBytes)
        return New
    end

    local function Align()
        Position += (8 - Position) % 8
    end

    --[[ local function GetChunks(ChunkSize: number): {buffer}
        -- Todo. Useful for unreliable events data splitting.
        error("Unimplemented")
    end ]]

    local Result = {
        WriteUInt = WriteBits;
        ReadUInt = ReadBits;

        WriteInt = function(Bits: number, Value: number)
            if (Bits == 0) then
                return
            end

            if (Value < 0) then
                Value += b32lshift(1, Bits - 1) * 2
            end

            WriteBits(Bits, Value)
        end;
        ReadInt = function(Bits: number): number
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

        WriteFloat = function(Bits: number, Value: number)
            if (Bits == 0) then
                return
            end

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
            if (Bits == 0) then
                return 0
            end

            -- We'll support non standard precision floats in the future.
            if (Bits > 32) then
                bwriteu32(SampleBuffer, 0, ReadBits(32))
                bwriteu32(SampleBuffer, 4, ReadBits(32))
                return breadf64(SampleBuffer, 0)
            end

            bwriteu32(SampleBuffer, 0, ReadBits(32))
            return breadf32(SampleBuffer, 0)
        end;
        --[[ WriteFloat = function(Bits: number, Value: number, Exponent: number?)
            if (Bits > 32) then
                bwritef64(SampleBuffer, 0, Value)
                WriteBits(32, breadu32(SampleBuffer, 0))
                WriteBits(32, breadu32(SampleBuffer, 4))
                return
            end
        
            if (Bits == 32 and (Exponent == 8 or Exponent == nil)) then
                bwritef32(SampleBuffer, 0, Value)
                WriteBits(32, breadu32(SampleBuffer, 0))
                return
            end

            Exponent = Exponent or mceil(Bits / 4)

            local Mantissa = Bits - Exponent - 1
            local ExponentMask = b32lshift(1, Exponent) - 1
            local MantissaMask = b32lshift(1, Mantissa) - 1
        
            local Sign = (Value < 0 and 1 or 0)
            local SignBit = b32lshift(Sign, Bits - 1)
        
            if (Value == 0) then
                WriteBits(Bits, 0)
                return
            end
            
            if (Value ~= Value) then
                local NanBits = SignBit + b32lshift(ExponentMask, Mantissa) + 1
                WriteBits(Bits, NanBits)
                return
            end
            
            if (Value == mhuge or Value == mnhuge) then
                local InfBits = SignBit + b32lshift(ExponentMask, Mantissa)
                WriteBits(Bits, InfBits)
                return
            end
        
            local FrexpMantissa, FrexpExponent = mfrexp(mabs(Value))
            local BiasedExp = FrexpExponent + b32lshift(1, Exponent - 1) - 2
        
            if (BiasedExp <= 0) then
                FrexpMantissa = mldexp(FrexpMantissa, BiasedExp)
                BiasedExp = 0
            end
        
            if (BiasedExp >= ExponentMask) then
                local InfBits = SignBit + b32lshift(ExponentMask, Mantissa)
                WriteBits(Bits, InfBits)
                return
            end
        
            local MantissaBits = b32band((FrexpMantissa * 2 - 1) * (2 ^ Mantissa), MantissaMask)
            local Result = SignBit + b32lshift(BiasedExp, Mantissa) + MantissaBits
            WriteBits(Bits, Result)
        end;
        ReadFloat = function(Bits: number, Exponent: number?): number
            if (Bits > 32) then
                bwriteu32(SampleBuffer, 0, ReadBits(32))
                bwriteu32(SampleBuffer, 4, ReadBits(32))
                return breadf64(SampleBuffer, 0)
            end
        
            if (Bits == 32 and (Exponent == 8 or Exponent == nil)) then
                bwriteu32(SampleBuffer, 0, ReadBits(32))
                return breadf32(SampleBuffer, 0)
            end
        
            Exponent = Exponent or mceil(Bits / 4)

            local Value = ReadBits(Bits)
            local BitLess = Bits - 1
            local Mantissa = BitLess - Exponent
            local ExponentMask = b32lshift(1, Exponent) - 1
            local ExponentBits = b32band(b32rshift(Value, Mantissa), ExponentMask)
            local MantissaBits = b32band(Value, b32lshift(1, Mantissa) - 1)
            local ExponentBias = b32lshift(1, Exponent - 1) - 1
            local Sign = (b32extract(Value, BitLess) == 1 and -1 or 1)
        
            local MantissaValue = MantissaBits / (2 ^ Mantissa)
        
            if (ExponentBits == 0) then
                if (MantissaBits == 0) then
                    return (Sign > 0 and 0 or -0)
                else
                    return Sign * mldexp(MantissaValue, 1 - ExponentBias)
                end
            elseif (ExponentBits == ExponentMask) then
                return (MantissaBits == 0 and (Sign > 0 and mhuge or mnhuge) or NAN)
            end
        
            local UnbiasedExp = ExponentBits - ExponentBias
            MantissaValue += 1
            return Sign * mldexp(MantissaValue, UnbiasedExp)
        end; ]]

        WriteBuffer = function(Subject: buffer, Length: number)
            if (Length == 0) then
                return
            end

            -- Buffer is byte-aligned from start to end, copy it directly using inbuilt copy (faster).
            -- BitSerializer only does this for writes which are generally large (buffer, string) as it
            -- would otherwise be slower for realistic usages.
            if (Position % 8 == 0 and Length % 8 == 0) then
                local NewPosition = CheckResize(Length)
                bcopy(Buffer, Position // 8, Subject, 0, Length // 8)
                Position = NewPosition
                return
            end

            local CurrentPos = 0
            local To1 = Length - 32
            local To2 = Length - 8

            while (CurrentPos < To1) do
                WriteBits(32, breadbits(Subject, CurrentPos, 32))
                CurrentPos += 32
            end

            while (CurrentPos < To2) do
                WriteBits(8, breadbits(Subject, CurrentPos, 8))
                CurrentPos += 8
            end

            if (CurrentPos < Length) then
                local Remaining = Length - CurrentPos
                WriteBits(Remaining, breadbits(Subject, CurrentPos, Remaining))
            end
        end;
        ReadBuffer = function(Length: number): buffer
            if (Length == 0) then
                return bcreate(0)
            end

            if (Position % 8 == 0 and Length % 8 == 0) then
                local Temp = bcreate(Length)
                local NewPosition = CheckResize(Length)
                bcopy(Temp, 0, Buffer, Position // 8, Length // 8)
                Position = NewPosition
                return Temp
            end

            local Result = bcreate(mceil(Length / 8))
            local CurrentPos = 0
            local To1 = Length - 32
            local To2 = Length - 8

            while (CurrentPos < To1) do
                bwritebits(Result, CurrentPos, 32, ReadBits(32))
                CurrentPos += 32
            end

            while (CurrentPos < To2) do
                bwritebits(Result, CurrentPos, 8, ReadBits(8))
                CurrentPos += 8
            end

            if (CurrentPos < Length) then
                local Remaining = Length - CurrentPos
                bwritebits(Result, CurrentPos, Remaining, ReadBits(Remaining))
            end

            return Result
        end;

        WriteString = function(String: string, Length: number)
            if (Length == 0) then
                return
            end

            if (Position % 8 == 0 and Length % 8 == 0) then
                local NewPosition = CheckResize(Length)
                bwritestring(Buffer, Position // 8, String)
                Position = NewPosition
                return
            end

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
            if (Length == 0) then
                return ""
            end

            if (Position % 8 == 0 and Length % 8 == 0) then
                local NewPosition = CheckResize(Length)
                local Result = breadstring(Buffer, Position // 8, Length // 8)
                Position = NewPosition
                return Result
            end

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

            return btostring(Result)
        end;

        SetPosition = function(Bit: number)
            Position = Bit
        end;
        GetPosition = function()
            return Position
        end;
        Align = Align;

        GetClippedBuffer = GetClippedBuffer;
        GetBuffer = function()
            return Buffer :: buffer
        end;

        Type = "Bit";
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
Test.Align()
Test.WriteString("Mraow", 8 * 5)
Test.WriteInt(8, -128)
Test.Align()
Test.WriteBuffer(buffer.fromstring("AHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHH"), 8 * 38)

Test.SetPosition(0)

print(Test.ReadUInt(1))
print(Test.ReadUInt(17))
print(Test.ReadUInt(2))
print(Test.ReadFloat(64))
Test.Align()
print(Test.ReadString(8 * 5))
print(Test.ReadInt(8))
Test.Align()
print(buffer.tostring(Test.ReadBuffer(8 * 38))) ]]

return BitSerializer