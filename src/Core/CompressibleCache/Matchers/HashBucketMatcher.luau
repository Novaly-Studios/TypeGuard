--!optimize 2
--!native

local Types = require(script.Parent.Parent._Types)
type Matcher = Types.Matcher

type HashBucketMatcherConfig = {
    --- Limit on the number of matches the algorithm will find.
    --- Should be low when there are huge numbers of repeated
    --- words which will go into the same bucket (to avoid nasty
    --- slow linear search on them).
    MaxmimumMatchChain: number?;

    --- Maximum size for a bucket of match positions. Higher
    --- values will increase memory usage and decrease speed,
    --- but also increase compression potential.
    BucketMaxSize: number?;

    --- Fill in hashes for strings in between matches. Decreases
    --- performance but increases compression potential.
    MatchFill: boolean?;

    --- When to stop searching for matches after finding a "good
    --- enough" percentage of the maximum match size.
    MatchExit: number?;
}

local tblclear = table.clear

local mthmax = math.max

local function HashBucketMatcher(Config: HashBucketMatcherConfig?): Matcher
    local MaxmimumMatchChain = if (Config) then Config.MaxmimumMatchChain or 16 else 16
    assert(type(MaxmimumMatchChain) == "number", "MaxmimumMatchChain was not a number")
    assert(MaxmimumMatchChain > 0, "MaxmimumMatchChain must be at least 1")

    local BucketMaxSize = if (Config) then Config.BucketMaxSize or 8 else 8
    assert(type(BucketMaxSize) == "number", "BucketMaxSize was not a number")
    assert(BucketMaxSize > 0, "BucketMaxSize must be at least 1")

    local MatchExit = if (Config) then Config.MatchExit or 1 else 1
    assert(type(MatchExit) == "number", "MatchExit was not a number")
    assert(MatchExit > 0 and MatchExit <= 1, "MatchExit must be between 0 and 1 (inclusive)")

    local MatchFill = if (Config) then Config.MatchFill or true else true
    assert(type(MatchFill) == "boolean", "MatchFill was not a boolean")

    local MatchExitUnits
    local HistorySize
    local LengthUnits
    local MaxPosition
    local FutureSize
    local FindMatch
    local Read4

    local Map = {}

    local function Initial(History, Future, Length, BufferRead4Function, FindMatchFunction)
        HistorySize = History
        LengthUnits = Length
        FutureSize = Future
        FindMatch = FindMatchFunction
        Read4 = BufferRead4Function

        MatchExitUnits = mthmax(1, (FutureSize * MatchExit) // 1)
        MaxPosition = LengthUnits - 4
    end

    local function Cleanup()
        tblclear(Map)
    end

    local function Offset(Amount)
        for _, Bucket in Map do
            for Index = 2, #Bucket do
                Bucket[Index] += Amount
            end
        end
    end

    local function _RegisterHash(Buffer, Position)
        -- Fetch substring 3 characters before current.
        -- Check if bucket exists for those characters, create if not.
        -- Circular buffer to prevent huge amount of iteration later.
        local StartPosition = Position - 4
        local InsertKey = Read4(Buffer, StartPosition)
        local InsertBucket = Map[InsertKey]

        if (InsertBucket) then
            local Size = InsertBucket[1]
            Size = (Size + 1) % BucketMaxSize
            InsertBucket[1] = Size
            InsertBucket[Size + 2] = StartPosition
        else
            Map[InsertKey] = {0, StartPosition}
        end
    end

    local function Match(Buffer, Current)
        -- Start matching at n bytes...
        -- End matching at buffer length - n bytes...
        if (Current < 4 or Current > MaxPosition) then
            return nil, nil
        end

        -- Fetch substring 3 characters forward including current.
        local MatchKey = Read4(Buffer, Current)
        local MatchBucket = Map[MatchKey]

        if (MatchBucket) then
            local LongestMatchPosition
            local LongestMatchLength = 4
            local Count = 0

            for Index = #MatchBucket, 2, -1 do
                Count += 1

                if (Count > MaxmimumMatchChain) then
                    break
                end

                local CandidatePosition = MatchBucket[Index]

                -- Exclude positions outside of history window.
                -- Might not have been cleaned yet since cleanup is periodic for speed.
                if (CandidatePosition < Current - HistorySize) then
                    continue
                end

                -- Find how many units both buffers remain equal for.
                local Length = FindMatch(4, Current, CandidatePosition)

                if (Length < LongestMatchLength) then
                    continue
                end

                LongestMatchPosition = CandidatePosition
                LongestMatchLength = Length

                -- Terminate early with a good enough match to avoid extra processing.
                if (Length >= MatchExitUnits) then
                    break
                end
            end

            if (LongestMatchPosition) then
                -- Add new hashes which it has encountered along the sequence.
                if (MatchFill) then
                    for Position = Current, Current + LongestMatchLength - 4 do
                        _RegisterHash(Buffer, Position)
                    end
                end

                return Current - LongestMatchPosition, LongestMatchLength
            end
        end

        _RegisterHash(Buffer, Current)
        return 1, nil
    end

    return {
        Initial = Initial;
        Cleanup = Cleanup;
        Offset = Offset;
        Match = Match;
    }
end

return HashBucketMatcher