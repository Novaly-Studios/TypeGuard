--!optimize 2
--!native

if (not script and Instance) then
    script = game:GetService("ReplicatedFirst").TypeGuard.Util.Debug
end

local bwritestring = buffer.writestring
local bcreate = buffer.create
local bcopy = buffer.copy
local blen = buffer.len

local mceil = math.ceil
local mlog = math.log

local DEFAULT_MIN_SIZE = 16

local function ReadError()
    error("DebugSerializer only for serialization, not deserialization")
end

local function EmptyFunction() end

--- This is not meant to be fast, but rather to be human-readable for debugging
--- or optimization purposes.
local function DebugSerializer(Buffer: buffer?, Size: number?)
    Size = Size or (Buffer and blen(Buffer :: buffer)) or DEFAULT_MIN_SIZE
    Buffer = Buffer or bcreate(Size :: number)

    local Indentation = ""
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

    local function RawWriteString(String: string, Length: number)
        local Bytes = mceil(Length / 8)
        CheckResize(Bytes)
        bwritestring(Buffer :: buffer, Position, String, Bytes)
        Position += Bytes
    end

    local function Context(Name: string?)
        if (Name == nil) then
            Indentation = Indentation:sub(1, #Indentation - 2)

            local Write = `{Indentation}End\n`
            RawWriteString(Write, #Write * 8)
            return
        end

        local Write = `{Indentation}{Name}\n`
        RawWriteString(Write, #Write * 8)
        Indentation ..= "\t|"
    end

    local Result = {
        Context = Context;

        WriteUInt = function(Bits: number, Value: number)
            local Write = `{Indentation}[BUFFER] UInt{Bits}: {Value}\n`
            RawWriteString(Write, #Write * 8)
        end;
        ReadUInt = ReadError;

        WriteInt = function(Bits: number, Value: number)
            local Write = `{Indentation}[BUFFER] Int{Bits}: {Value}\n`
            RawWriteString(Write, #Write * 8)
        end;
        ReadInt = ReadError;

        WriteFloat = function(Bits: number, Value: number)
            local Write = `{Indentation}[BUFFER] Float{Bits}: {Value}\n`
            RawWriteString(Write, #Write * 8)
        end;
        ReadFloat = ReadError;

        WriteString = function(String: string, Length: number)
            local Write = `{Indentation}[BUFFER] String{Length}: {String}\n`
            RawWriteString(Write, #Write * 8)
        end;
        ReadString = ReadError;

        WriteBuffer = function(Subject: buffer, From: number, To: number)
            local Write = `{Indentation}[BUFFER] Buffer: [{From} -> {To}] {buffer.tostring(Subject)}\n`
            RawWriteString(Write, #Write * 8)
        end;
        ReadBuffer = ReadError;

        SetPosition = ReadError;
        GetPosition = function(): number
            return Position * 8
        end;
        Extend = CheckResize;
        Align = EmptyFunction;

        GetBuffer = function()
            return Buffer :: buffer
        end;
        GetClippedBuffer = GetClippedBuffer;

        Constructor = DebugSerializer;
        Type = "Debug";
    }

    return Result
end

return DebugSerializer