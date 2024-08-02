--!optimize 2
--!native

local bwritestring = buffer.writestring
local breadstring = buffer.readstring
local btostring = buffer.tostring
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

--- Abstracts over buffers with an auto-resize mechanism. All lengths are
--- represented in bits as a standard to allow forward-compatible switches
--- between byte-level and bit-level buffers. Intended for long duration
--- lifetime.
local function ByteSerializer(Buffer: buffer?, Size: number?, ResizeFactor: number?)
    ResizeFactor = ResizeFactor or 2
    Buffer = Buffer or bcreate(Size or 16)
    Size = Size or blen(Buffer :: buffer)

    local Position = 0

    local function CheckResize(AdditionalBytes: number)
        local Resize = ResizeFactor :: number ^ math.ceil(math.log(Position + AdditionalBytes, ResizeFactor))
        if (Resize == Size) then
            return
        end

        local NewBuffer = bcreate(Resize)
        bcopy(NewBuffer, 0, Buffer :: buffer)
        Buffer = NewBuffer
        Size = Resize
    end

    local function GetClippedBuffer(): buffer
        local New = bcreate(Position)
        bcopy(New, 0, Buffer :: any, 0, Position)
        return New
    end

    local function GetChunks(ChunkSize: number): {buffer}
        local Chunks = math.ceil(Position / ChunkSize)
        local Result = table.create(Chunks)
        -- Todo. Useful for unreliable events data splitting.
        error("Unimplemented")
        return Result
    end

    return {
        WriteUInt = function(Bits: number, Value: number)
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

        WriteInt = function(Bits: number, Value: number)
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

        WriteFloat = function(Bits: number, Value: number)
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

        WriteString = function(String: string)
            local Bytes = #String
            CheckResize(Bytes)
            bwritestring(Buffer :: buffer, Position, String)
            Position += Bytes
        end;
        ReadString = function(Length: number): string
            local Bytes = math.ceil(Length / 8)
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
        SetPositionBytes = function(Byte: number)
            if (Byte < 0 or Byte > Size) then
                error(`Position out of bounds (0-${Size})`)
            end

            Position = Byte
        end;
        GetPositionBytes = function(): number
            return Position
        end;
        GetClippedBuffer = GetClippedBuffer;
        GetChunks = GetChunks;
        GetBuffer = function(): buffer
            return Buffer :: buffer
        end;
        ToClippedString = function()
            return btostring(GetClippedBuffer())
        end;
    }
end

return ByteSerializer
