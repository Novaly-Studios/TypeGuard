--!optimize 2
--!native

if (not script and Instance) then
    script = game:GetService("ReplicatedFirst").TypeGuard.Util.CompressedSerializer
end

local CompressTypes = require(script._Types)
local Matchers = require(script.Matchers)
local Types = require(script.Parent._Types)

local tblclone = table.clone

local bufcreate = buffer.create
local bufcopy = buffer.copy

local mthceil = math.ceil
local mthlog = math.log

type CompressorConfig = {
    --- The size of the history buffer, which is used to store previously seen data.
    --- Higher value = more potential for compression matches but more memory usage and lower performance.
    HistoryBufferSize: number?;

    --- The size of the future buffer, which is used to store data that will be seen in the future.
    --- Higher value = more potential for compression matches but lower performance.
    FutureBufferSize: number?;

    --- Compress new block after every n bits.
    ChunkSize: number?;

    --- How many bits to step at a time.
    BitsStep: number?;

    --- The matcher implementation to use for finding repeated substrings to compress.
    Matcher: CompressTypes.Matcher?;
}

--- Serializer which compresses data after every n bits written.
local function CompressedSerializer(Serializer: Types.Serializer, Config: CompressorConfig?)
    Config = Config or {}

    local HistoryBufferSize = (Config and Config.HistoryBufferSize or 4096)
        local HistoryBufferBits = mthceil(mthlog(HistoryBufferSize, 2))
    local FutureBufferSize = (Config and Config.FutureBufferSize or 16)
        local FutureBufferBits = mthceil(mthlog(FutureBufferSize, 2))
    local ChunkSize = (Config and Config.ChunkSize or 64 * 8)
    local BitsStep = (Config and Config.BitsStep or 8)
    assert(math.log(BitsStep, 2) % 1 == 0, "BitsStep must be a power of 2")

    local Matcher = (Config and Config.Matcher or Matchers.HashMatcher())
        local MatcherMatch = Matcher.Match

    -- Position represented in bits.
    local Position = 0

    local function CompressBlock(Amount: number)
        local StartPosition = Position // BitsStep

        for Index = 0, Amount - 1 do
            local GoBack, GoForward = MatcherMatch(Buffer, StartPosition + Index)

            -- Back reference matched.
            if (GoForward) then

            end
        end
    end

    local LastPosition = 0

    local function CheckCompress()
        --[[ while (LastPosition < Position) do
            CompressBlock(ChunkSize)
            LastPosition = 
        end ]]
    end

    --[[ local function GetChunks(ChunkSize)
        -- Todo. Useful for unreliable events data splitting.
        error("Unimplemented")
    end ]]

    local Result = tblclone(Serializer)

    for Key, Value in Result do
        if (Key:sub(1, 5) == "Write" and type(Value) == "function") then
            local OriginalFunction = Value
            Result[Key] = function(...)
                OriginalFunction(...)
                CheckCompress()
            end
        end
    end

    return Result
end

return CompressedSerializer