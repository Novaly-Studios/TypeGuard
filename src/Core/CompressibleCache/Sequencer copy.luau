--!optimize 2
--!native

if (not script and Instance) then
    script = game:GetService("ReplicatedFirst").TypeGuard.Core.CompressibleCache.Sequencer
end

local Util = require(script.Parent.Parent.Parent.Util)
    local ByteSerializer = Util.Serializers.Byte
    local BitSerializer = Util.Serializers.Bit

local Matchers = require(script.Parent.Matchers)

local Types = require(script.Parent._Types)
type Matcher = Types.Matcher

local dbgprofilebegin = debug.profilebegin or function() end
local dbgprofileend = debug.profileend or function() end

local b32lshift = bit32.lshift
local b32rshift = bit32.rshift
local b32band = bit32.band

local bufreadbits = buffer.readbits
local bufreadu32 = buffer.readu32
local bufreadu8 = buffer.readu8
local buflen = buffer.len

local mthceil = math.ceil
local mthmin = math.min
local mthlog = math.log

type Serializer = (typeof(BitSerializer) | typeof(ByteSerializer))

export type Config = {
    --- Prevents excessive buffer resizing and moving, the shared buffer can only be clipped
    --- once it exceeeds n * window size. This variable is the n factor. Costs more memory.
    SharedBufferClipFactor: number?;

    --- The size of the history buffer, which is used to store previously seen data.
    --- Higher value = more potential for compression matches but more memory usage and lower performance.
    HistoryBufferSize: number?;

    --- The size of the future buffer, which is used to store data that will be seen in the future.
    --- Higher value = more potential for compression matches but lower performance.
    FutureBufferSize: number?;

    --- An optional shared buffer used to store repeated substrings between compressions.
    SharedBuffer: Serializer?;

    --- The serializer type to use for the output buffer (bit saves space, but is slower).
    Serializer: Serializer?;

    --- How many bits to step at a time.
    BitsStep: number?;

    --- The matcher implementation to use for finding repeated substrings to compress.
    Matcher: Matcher?;
}

local function Sequencer(Config: Config?)
    local SharedBufferClipFactor = (Config and Config.SharedBufferClipFactor or 4)
    local HistoryBufferSize = (Config and Config.HistoryBufferSize or 4096)
    local HistoryBufferBits = mthceil(mthlog(HistoryBufferSize, 2))
    local FutureBufferSize = (Config and Config.FutureBufferSize or 16)
    local FutureBufferBits = mthceil(mthlog(FutureBufferSize, 2))
    local SharedBuffer = (Config and Config.SharedBuffer or nil)
        local SharedBufferWriteBuffer = (SharedBuffer and SharedBuffer.WriteBuffer or nil)
        local SharedBufferGetPosition = (SharedBuffer and SharedBuffer.GetPosition or nil)
        local SharedBufferSetPosition = (SharedBuffer and SharedBuffer.SetPosition or nil)
        local SharedBufferGetBuffer = (SharedBuffer and SharedBuffer.GetBuffer or nil)
        local SharedBufferShrink = (SharedBuffer and SharedBuffer.Shrink or nil)
    local Serializer = (Config and Config.Serializer or BitSerializer)
    local BitsStep = (Config and Config.BitsStep or 8)
    assert(math.log(BitsStep, 2) % 1 == 0, "BitsStep must be a power of 2")
    assert(BitsStep >= 1 and BitsStep <= 8, "BitsStep must be between 1 and 8 (inclusive)")

    local CompressedOutput = Serializer()
        local CompressedOutputGetClippedBuffer = CompressedOutput.GetClippedBuffer
        local CompressedOutputSetPosition = CompressedOutput.SetPosition
        local CompressedOutputGetPosition = CompressedOutput.GetPosition
        local CompressedOutputWriteBuffer = CompressedOutput.WriteBuffer
        local CompressedOutputWriteFloat = CompressedOutput.WriteFloat
        local CompressedOutputWriteUInt = CompressedOutput.WriteUInt

    local DecompressedOutput = Serializer()

    local RunBuffer = Serializer()
        local RunBufferSetPosition = RunBuffer.SetPosition
        local RunBufferGetPosition = RunBuffer.GetPosition
        local RunBufferWriteUInt = RunBuffer.WriteUInt
        local RunBufferGetBuffer = RunBuffer.GetBuffer

    local Matcher = (Config and Config.Matcher or Matchers.HashMatcher())
        local MatcherInitial = Matcher.Initial
        local MatcherCleanup = Matcher.Cleanup
        local MatcherOffset = Matcher.Offset
        local MatcherMatch = Matcher.Match

    local function Compress(In: buffer, FromBit: number?, ToBit: number?): buffer
        dbgprofilebegin("Compress")

        local From = FromBit or 0
        local To = ToBit or buflen(In) * 8
        local Length = To - From

        if (SharedBuffer) then
            -- Write In to SharedBuffer.
            local StartPosition = SharedBufferGetPosition()
            SharedBufferWriteBuffer(In, From, To)
            Length += StartPosition
            SharedBufferSetPosition(StartPosition)
            In = SharedBufferGetBuffer()
        end

        local LengthUnits = Length / BitsStep

        if (LengthUnits % 1 ~= 0) then
            error("Input buffer length must be a multiple of BitsStep")
        end

        RunBufferSetPosition(0)

        local OptimizedReads = (BitsStep == 8)
        local FourUnits = BitsStep * 4

        local LastRunType -- 0 = Literal, 1 = Back Reference
        local RunsWritten = 0
        local Position = (SharedBuffer and SharedBufferGetPosition() or 0)
        local RunCount = 0

        local function WriteLastRun(Type: number)
            LastRunType = LastRunType or Type

            if ((LastRunType ~= Type or RunCount == 128) and RunCount > 0) then
                CompressedOutputWriteUInt(8, LastRunType + b32lshift(RunCount - 1, 1))

                if (LastRunType == 0) then
                    CompressedOutputWriteBuffer(In, Position - RunCount * BitsStep, Position)
                else
                    CompressedOutputWriteBuffer(RunBufferGetBuffer(), 0, RunBufferGetPosition())
                    RunBufferSetPosition(0)
                end

                RunsWritten += 1
                LastRunType = Type
                RunCount = 0
            end
        end

        local Read4 = (OptimizedReads and bufreadu32 or function(Buffer: buffer, Position: number)
            return bufreadbits(Buffer, Position * BitsStep, FourUnits)
        end)

        -- This function being defined here with raw buffer functions rather than Read4 in the specific
        -- matchers gives a significant performance boost.
        local FindMatch = (OptimizedReads and function(Length: number, Current: number, CandidatePosition: number): number
            while ((Current + Length + 4) < LengthUnits and (Length + 4) < FutureBufferSize and bufreadu32(In, Current + Length) == bufreadu32(In, CandidatePosition + Length)) do
                Length += 4
            end

            while ((Current + Length + 1) < LengthUnits and (Length + 1) < FutureBufferSize and bufreadu8(In, Current + Length) == bufreadu8(In, CandidatePosition + Length)) do
                Length += 1
            end

            return Length
        end or function(Length: number, Current: number, CandidatePosition: number): number
            while ((Current + Length + 4) < LengthUnits and Length < FutureBufferSize and bufreadbits(In, (Current + Length) * BitsStep, BitsStep) == bufreadbits(In, (CandidatePosition + Length) * BitsStep, BitsStep)) do
                Length += 4
            end

            while ((Current + Length + 1) < LengthUnits and Length < FutureBufferSize and bufreadbits(In, (Current + Length) * BitsStep, BitsStep) == bufreadbits(In, (CandidatePosition + Length) * BitsStep, BitsStep)) do
                Length += 1
            end

            return Length
        end)

        CompressedOutputSetPosition(64)
        MatcherInitial(HistoryBufferSize, FutureBufferSize, LengthUnits, Read4, FindMatch)

        while (Position < Length) do
            local GoBack, GoForward = MatcherMatch(In, Position // BitsStep)

            -- Back reference matched.
            if (GoForward) then
                WriteLastRun(1)
                RunCount += 1
                Position += GoForward * BitsStep
                RunBufferWriteUInt(HistoryBufferBits, GoBack - 1)
                RunBufferWriteUInt(FutureBufferBits, GoForward - 1)
                continue
            end

            -- New literals encountered.
            local Increment = (GoBack or 1)

            for _ = 1, Increment do
                WriteLastRun(0)
                Position += BitsStep
                RunCount += 1
            end
        end

        -- Write the last run, then a float to designate the number of runs.
        WriteLastRun(LastRunType == 0 and 1 or 0)

        local Temp = CompressedOutputGetPosition()
        CompressedOutputSetPosition(0)
        CompressedOutputWriteFloat(64, RunsWritten)
        CompressedOutputSetPosition(Temp)

        local Result = CompressedOutputGetClippedBuffer()

        if (SharedBuffer) then
            SharedBufferSetPosition(Length)
        else
            MatcherCleanup()
        end

        dbgprofileend()
        return Result
    end

    local function Decompress(In: buffer)
        dbgprofilebegin("Decompress")

        local TargetOutput = (SharedBuffer or DecompressedOutput)
            local TargetOutputGetClippedBuffer = TargetOutput.GetClippedBuffer
            local TargetOutputGetPosition = TargetOutput.GetPosition
            local TargetOutputWriteBuffer = TargetOutput.WriteBuffer
            local TargetOutputSetPosition = TargetOutput.SetPosition
            local TargetOutputReadBuffer = TargetOutput.ReadBuffer
            local TargetOutputGetBuffer = TargetOutput.GetBuffer
            local TargetOutputExtend = TargetOutput.Extend

        if (not SharedBuffer) then
            TargetOutputSetPosition(0)
        end

        local StartPosition = TargetOutputGetPosition()

        local InReader = Serializer(In) -- Todo: re-use object.
            local InReaderIncrementPosition = InReader.IncrementPosition
            local InReaderGetPosition = InReader.GetPosition
            local InReaderReadFloat = InReader.ReadFloat
            local InReaderReadUInt = InReader.ReadUInt

        local RunCount = InReaderReadFloat(64)

        for _ = 1, RunCount do
            local RunData = InReaderReadUInt(8)
            local Length = b32band(b32rshift(RunData, 1), 0b01111111) + 1
            local RunType = b32band(RunData, 1)

            -- Literal run.
            if (RunType == 0) then
                local BitLength = Length * BitsStep
                local InReaderPosition = InReaderGetPosition()

                -- Record new text in SharedBuffer.
                TargetOutputWriteBuffer(In, InReaderPosition, InReaderPosition + BitLength)
                InReaderIncrementPosition(BitLength)
                continue
            end

            -- Back reference run.
            for Count = 1, Length do
                local GoBack = InReaderReadUInt(HistoryBufferBits) * BitsStep + BitsStep
                local GoForward = InReaderReadUInt(FutureBufferBits) * BitsStep + BitsStep

                TargetOutputExtend(GoForward)

                local ReadBuffer = TargetOutputGetBuffer()
                local From = TargetOutputGetPosition() - GoBack

                if (GoBack < GoForward) then
                    -- The less performant case: copying a substring, then copying that substring again, etc..
                    -- That will happen when a lot of perfectly repeating strings are consecutive and matched.
                    local Accumulation = 0

                    while (Accumulation < GoForward) do
                        local Bits = mthmin(GoBack, GoForward - Accumulation)
                        local Start = From + Accumulation
                        TargetOutputWriteBuffer(ReadBuffer, Start, Start + Bits)
                        Accumulation += Bits
                    end
                else
                    -- The more performant case: copying only one existing substring.
                    TargetOutputWriteBuffer(ReadBuffer, From, From + GoForward)
                end
            end
        end

        local Result

        if (SharedBuffer) then
            -- Only copy subsection of the new strings written as the result if SharedBuffer is being used.
            -- Basically SharedBuffer is a concatenation of decompressed strings, this copies the last string.
            local CurrentPosition = TargetOutputGetPosition()
            TargetOutputSetPosition(StartPosition)
            Result = TargetOutputReadBuffer(CurrentPosition - StartPosition)
        else
            Result = TargetOutputGetClippedBuffer()
        end

        dbgprofileend()
        return Result
    end

    -- Untested.
    local function ClipSharedBuffer()
        local RawSharedBuffer = SharedBufferGetBuffer()
        local Maximum = HistoryBufferSize * SharedBufferClipFactor
        local Length = buflen(RawSharedBuffer)
        local Clip = Length - Maximum

        if (Clip > 0) then
            local AtPosition = (Length - Clip) * BitsStep
            SharedBufferWriteBuffer(RawSharedBuffer, 0, AtPosition)
            SharedBufferSetPosition(AtPosition)
            SharedBufferShrink()
            MatcherOffset(-Clip)
        end
    end

    return {
        -- ClipSharedBuffer = ClipSharedBuffer;
        Decompress = Decompress;
        Compress = Compress;
    }
end

-- Options:
-- - Entropy coding option (e.g. Huffman)
-- - Custom literal bit encoder function (e.g. for strings which may only use say alphanumeric characters as 6 bits)
-- - Custom match function (e.g. binary tree, prefix tree, hash table) [x]
-- - Synchronized compression and decompression between multiple calls [x]
-- - Relative encoding (e.g. A,B,C -> 1,1,1 literals), this can be part of the custom literal encoder / decoder

return Sequencer