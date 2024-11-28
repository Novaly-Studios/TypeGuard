--!optimize 2
--!native

if (not script) then
    script = game:GetService("ReplicatedFirst").TypeGuard.Util.ByteSerializer
end

local bwritestring = buffer.writestring
local breadstring = buffer.readstring
local bwriteu16 = buffer.writeu16
local bwritei16 = buffer.writei16
local bwriteu32 = buffer.writeu32
local bwritei32 = buffer.writei32
local bwritef32 = buffer.writef32
local bwritef64 = buffer.writef64
local bwriteu8 = buffer.writeu8
local bwritei8 = buffer.writei8
local breadu16 = buffer.readu16
local breadi16 = buffer.readi16
local breadu32 = buffer.readu32
local breadi32 = buffer.readi32
local breadf32 = buffer.readf32
local breadf64 = buffer.readf64
local breadu8 = buffer.readu8
local breadi8 = buffer.readi8
local bcreate = buffer.create
local bcopy = buffer.copy
local blen = buffer.len

local mceil = math.ceil
local mlog = math.log

local DEFAULT_MIN_SIZE = 16

--- Abstracts over buffers with an auto-resize mechanism. All lengths are
--- represented in bits as a standard to allow forward-compatible switches
--- between byte-level and bit-level buffers. Intended for long duration
--- lifetime.
local function ByteSerializer(Buffer: buffer?, Size: number?, ReadOnly: boolean?)
    Size = Size or (Buffer and blen(Buffer :: buffer)) or DEFAULT_MIN_SIZE
    Buffer = Buffer or bcreate(Size :: number)

    local Position = 0

    local function CheckResize(AdditionalBytes: number)
        -- As soon as we are about to hit the size limit, allocate a new buffer with double the size.
        local Sum = Position + AdditionalBytes
        if (Sum < Size) then
            return
        end

        Size = 2 ^ mceil(mlog(Sum, 2))
        local NewBuffer = bcreate(Size)
        bcopy(NewBuffer, 0, Buffer :: buffer)
        Buffer = NewBuffer
    end

    local function GetClippedBuffer(): buffer
        local New = bcreate(Position)
        bcopy(New, 0, Buffer :: any, 0, Position)
        return New
    end

    --[[ local function GetChunks(ChunkSize: number): {buffer}
        -- Todo. Useful for unreliable events data splitting.
        error("Unimplemented")
    end ]]

    local function WriteError()
        error("Attempt to write to read-only ByteSerializer")
    end

    local Result = {
        WriteUInt = ReadOnly and WriteError or function(Bits: number, Value: number)
            local Bytes = (Bits < 9 and 1 or Bits < 17 and 2 or 4)
            CheckResize(Bytes)
            local Writer = (Bytes == 1 and bwriteu8 or Bytes == 2 and bwriteu16 or bwriteu32)
            Writer(Buffer, Position, Value)
            Position += Bytes
        end;
        ReadUInt = function(Bits: number): number
            local Bytes = (Bits < 9 and 1 or Bits < 17 and 2 or 4)
            local Reader = (Bytes == 1 and breadu8 or Bytes == 2 and breadu16 or breadu32)
            local Value = Reader(Buffer, Position)
            Position += Bytes
            return Value
        end;

        WriteInt = ReadOnly and WriteError or function(Bits: number, Value: number)
            local Bytes = (Bits < 9 and 1 or Bits < 17 and 2 or 4)
            CheckResize(Bytes)
            local Writer = (Bytes == 1 and bwritei8 or Bytes == 2 and bwritei16 or bwritei32)
            Writer(Buffer, Position, Value)
            Position += Bytes
        end;
        ReadInt = function(Bits: number): number
            local Bytes = (Bits < 9 and 1 or Bits < 17 and 2 or 4)
            local Reader = (Bytes == 1 and breadi8 or Bytes == 2 and breadi16 or breadi32)
            local Value = Reader(Buffer, Position)
            Position += Bytes
            return Value
        end;

        WriteFloat = ReadOnly and WriteError or function(Bits: number, Value: number)
            local Bytes = (Bits < 33 and 4 or 8)
            CheckResize(Bytes)
            local Writer = (Bytes == 4 and bwritef32 or bwritef64)
            Writer(Buffer, Position, Value)
            Position += Bytes
        end;
        ReadFloat = function(Bits: number): number
            local Bytes = (Bits < 33 and 4 or 8)
            local Reader = (Bytes == 4 and breadf32 or breadf64)
            local Result = Reader(Buffer, Position)
            Position += Bytes
            return Result
        end;

        WriteString = ReadOnly and WriteError or function(String: string, Length: number)
            local Bytes = mceil(Length / 8)
            CheckResize(Bytes)
            bwritestring(Buffer :: buffer, Position, String, Bytes)
            Position += Bytes
        end;
        ReadString = function(Length: number): string
            local Bytes = mceil(Length / 8)
            local Result = breadstring(Buffer :: buffer, Position, Bytes)
            Position += Bytes
            return Result
        end;

        SetPosition = function(Bit: number)
            local Bytes = Bit // 8
            if (Bytes < 0 or Bytes > Size) then
                error(`Position out of bounds (0-{Size :: number * 8})`)
            end
            Position = Bytes
        end;
        GetPosition = function(): number
            return Position * 8
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

return ByteSerializer