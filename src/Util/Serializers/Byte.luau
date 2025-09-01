--!optimize 2
--!native

if (not script and Instance) then
    script = game:GetService("ReplicatedFirst").TypeGuard.Util.ByteSerializer
end

local Types = require(script.Parent._Types)

local bufwritestring = buffer.writestring
local bufreadstring = buffer.readstring
local bufwriteu16 = buffer.writeu16
local bufwritei16 = buffer.writei16
local bufwriteu32 = buffer.writeu32
local bufwritei32 = buffer.writei32
local bufwritef32 = buffer.writef32
local bufwritef64 = buffer.writef64
local bufwriteu8 = buffer.writeu8
local bufwritei8 = buffer.writei8
local bufreadu16 = buffer.readu16
local bufreadi16 = buffer.readi16
local bufreadu32 = buffer.readu32
local bufreadi32 = buffer.readi32
local bufreadf32 = buffer.readf32
local bufreadf64 = buffer.readf64
local bufreadu8 = buffer.readu8
local bufreadi8 = buffer.readi8
local bufcreate = buffer.create
local bufcopy = buffer.copy
local buflen = buffer.len

local dbginfo = debug.info

local mthceil = math.ceil
local mthlog = math.log

local DEFAULT_MIN_SIZE = 16

local function EmptyFunction() end

--- Abstracts over buffers with an auto-resize mechanism. All lengths are
--- represented in bits as a standard to allow forward-compatible switches
--- between byte-level and bit-level buffers. Intended for long duration
--- lifetime.
local ByteSerializer: Types.SerializerConstructor = function(Buffer, Size, ProfilerTags)
    Size = Size or (Buffer and buflen(Buffer)) or DEFAULT_MIN_SIZE
    Buffer = Buffer or bufcreate(Size)

    local Position = 0

    local function CheckResize(AdditionalBytes)
        -- As soon as we are about to hit the size limit, allocate a new buffer with double the size.
        local Sum = Position + AdditionalBytes

        if (Sum < Size) then
            return Sum
        end

        Size = 2 ^ mthceil(mthlog(Sum, 2))
        local NewBuffer = bufcreate(Size)
        bufcopy(NewBuffer, 0, Buffer)
        Buffer = NewBuffer
        return Sum
    end

    --[[ local function GetChunks(ChunkSize)
        -- Todo. Useful for unreliable events data splitting.
        error("Unimplemented")
    end ]]

    local Result: Types.Serializer; Result = {
        WriteUInt = function(Bits, Value)
            if (Bits == 0) then
                return
            end

            local Bytes = (Bits < 9 and 1 or Bits < 17 and 2 or 4)
            local NewPosition = CheckResize(Bytes)
            local Writer = (Bytes == 1 and bufwriteu8 or Bytes == 2 and bufwriteu16 or bufwriteu32)
            Writer(Buffer, Position, Value)
            Position = NewPosition
        end;
        ReadUInt = function(Bits)
            if (Bits == 0) then
                return 0
            end

            local Bytes = (Bits < 9 and 1 or Bits < 17 and 2 or 4)
            local Reader = (Bytes == 1 and bufreadu8 or Bytes == 2 and bufreadu16 or bufreadu32)
            local Value = Reader(Buffer, Position)
            Position += Bytes
            return Value
        end;

        WriteInt = function(Bits, Value)
            if (Bits == 0) then
                return
            end

            local Bytes = (Bits < 9 and 1 or Bits < 17 and 2 or 4)
            local NewPosition = CheckResize(Bytes)
            local Writer = (Bytes == 1 and bufwritei8 or Bytes == 2 and bufwritei16 or bufwritei32)
            Writer(Buffer, Position, Value)
            Position = NewPosition
        end;
        ReadInt = function(Bits)
            if (Bits == 0) then
                return 0
            end

            local Bytes = (Bits < 9 and 1 or Bits < 17 and 2 or 4)
            local Reader = (Bytes == 1 and bufreadi8 or Bytes == 2 and bufreadi16 or bufreadi32)
            local Value = Reader(Buffer, Position)
            Position += Bytes
            return Value
        end;

        WriteFloat = function(Bits, Value)
            if (Bits == 0) then
                return
            end

            local Bytes = (Bits < 33 and 4 or 8)
            local NewPosition = CheckResize(Bytes)
            local Writer = (Bytes == 4 and bufwritef32 or bufwritef64)
            Writer(Buffer, Position, Value)
            Position = NewPosition
        end;
        ReadFloat = function(Bits)
            if (Bits == 0) then
                return 0
            end

            local Bytes = (Bits < 33 and 4 or 8)
            local Reader = (Bytes == 4 and bufreadf32 or bufreadf64)
            local Result = Reader(Buffer, Position)
            Position += Bytes
            return Result
        end;

        WriteBuffer = function(Subject, From, To)
            local Length = To - From

            if (Length == 0) then
                return
            end

            local LengthBytes = mthceil(Length / 8)
            local NewPosition = CheckResize(LengthBytes)
            bufcopy(Buffer, Position, Subject, mthceil(From / 8), LengthBytes)
            Position = NewPosition
        end;
        ReadBuffer = function(Length)
            if (Length == 0) then
                return bufcreate(0)
            end

            local Bytes = mthceil(Length / 8)
            local Result = bufcreate(Bytes)
            bufcopy(Result, 0, Buffer, Position, Bytes)
            Position += Bytes
            return Result
        end;

        WriteString = function(String, Length)
            if (Length == 0) then
                return
            end

            local Bytes = mthceil(Length / 8)
            local NewPosition = CheckResize(Bytes)
            bufwritestring(Buffer, Position, String, Bytes)
            Position = NewPosition
        end;
        ReadString = function(Length)
            if (Length == 0) then
                return ""
            end

            local Bytes = mthceil(Length / 8)
            local Result = bufreadstring(Buffer, Position, Bytes)
            Position += Bytes
            return Result
        end;

        IncrementPosition = function(Increment)
            Position += mthceil(Increment / 8)
        end;
        SetPosition = function(Bit)
            local Bytes = Bit // 8

            if (Bytes < 0 or Bytes > Size) then
                error(`Position out of bounds (0-{Size * 8})`)
            end

            Position = Bytes
        end;
        GetPosition = function()
            return Position * 8
        end;
        Extend = CheckResize;
        Align = EmptyFunction;

        GetClippedBuffer = function()
            local New = bufcreate(Position)
            bufcopy(New, 0, Buffer, 0, Position)
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
        Type = "Byte";
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

return ByteSerializer