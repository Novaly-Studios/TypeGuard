--!optimize 2
--!native

local Types = require(script.Parent.Parent._Types)
type Matcher = Types.Matcher

type HashMatcherConfig = {
    --- How quickly to build up the skip voids mechanism (if enabled).
    --- Default 2.
    SkipVoidsAggressiveness: number?;

    --- How large the skip voids increment can grow to.
    --- Default 3.
    SkipVoidsMaximum: number?;

    --- Skips regions which are likely blank to increase performance.
    --- Decreased compression potential.
    --- Default true.
    SkipVoids: boolean?;

    --- Fill in hashes for substrings in between matches. Decreases
    --- performance but increases compression potential.
    --- Default false.
    MatchFill: boolean?;
}

local tblclear = table.clear

local mthmin = math.min

local function HashMatcher(Config: HashMatcherConfig?): Matcher
    local SkipVoidsAggressiveness = if (Config) then Config.SkipVoidsAggressiveness or 2 else 2
    assert(type(SkipVoidsAggressiveness) == "number", "SkipVoidsAggressiveness was not a number")
    assert(SkipVoidsAggressiveness >= 1, "SkipVoidsAggressiveness was less than 1")

    local SkipVoidsMaximum = if (Config) then Config.SkipVoidsMaximum or 4 else 4
    assert(type(SkipVoidsMaximum) == "number", "SkipVoidsMaximum was not a number")
    assert(SkipVoidsMaximum >= 2, "SkipVoidsMaximum was less than 2")

    local SkipVoids = if (Config) then Config.SkipVoids or true else true
    assert(type(SkipVoids) == "boolean", "SkipVoids was not a boolean")

    local MatchFill = if (Config) then Config.MatchFill or false else false
    assert(type(MatchFill) == "boolean", "MatchFill was not a boolean")

    local LengthUnits
    local MaxPosition
    local HistorySize
    local Increment
    local FindMatch
    local Read4

    local Map = {}

    local function Initial(History, _Future, Length, BufferRead4Function, FindMatchFunction)
        LengthUnits = Length
        MaxPosition = LengthUnits - 4
        HistorySize = History
        FindMatch = FindMatchFunction
        Increment = 1
        Read4 = BufferRead4Function
    end

    local function Cleanup()
        tblclear(Map)
    end

    local function Offset(Amount)
        for Key in Map do
            Map[Key] += Amount
        end
    end

    local function Match(Buffer, Current)
        if (Current > MaxPosition) then
            return nil, nil
        end

        local MatchKey = Read4(Buffer, Current)
        local CandidatePosition = Map[MatchKey]
        Map[MatchKey] = Current

        if (CandidatePosition) then
            local Diff = Current - CandidatePosition

            if (Diff <= HistorySize and Diff > 3) then
                local Length = FindMatch(4, Current, CandidatePosition)

                if (MatchFill) then
                    for Position = Current, Current + Length - 4 do
                        Map[Read4(Buffer, Position)] = Position
                    end
                end

                Increment = 1
                return Diff, Length
            end
        end

        if (SkipVoids) then
            Increment = mthmin(Increment + SkipVoidsAggressiveness, SkipVoidsMaximum)

            if (Current + Increment > MaxPosition) then
                return MaxPosition - Current + 1, nil
            end

            return Increment, nil
        end

        return 1, nil
    end

    return {
        Initial = Initial;
        Cleanup = Cleanup;
        Offset = Offset;
        Match = Match;
    }
end

return HashMatcher