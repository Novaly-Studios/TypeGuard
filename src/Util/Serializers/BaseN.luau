--!optimize 2
--!native

if (not script and Instance) then
    script = game:GetService("ReplicatedFirst").TypeGuard.Util.Encoders.BaseN
end

local Types = require(script.Parent._Types)

local dbgprofilebegin = (debug and debug.profilebegin or function() end)
local dbgprofileend = (debug and debug.profileend or function() end)

local buffromstring = buffer.fromstring
local bufwritebits = buffer.writebits
local bufreadbits = buffer.readbits
local bufwriteu8 = buffer.writeu8
local bufcreate = buffer.create
local bufreadu8 = buffer.readu8
local buflen = buffer.len

local tblclone = table.clone

local mthceil = math.ceil
local mthmin = math.min
local mthlog = math.log

local ReverseBaseCharacters = table.create(256)
local BaseCharacters = buffromstring("0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz+/")
local BaseCharactersCount = buflen(BaseCharacters)

for Index = 0, BaseCharactersCount - 1 do
    ReverseBaseCharacters[bufreadu8(BaseCharacters, Index) + 1] = Index
end

local function BaseNSerializer(Serializer: Types.Serializer, Base: number)
    if (Base < 2 or Base > BaseCharactersCount) then
        error(`Base must be between 2 and {BaseCharactersCount}`)
    end

    local Result: Types.Serializer = tblclone(Serializer)
        local GetPosition = Result.GetPosition
        local SetBuffer = Result.SetBuffer
        local GetBuffer = Result.GetBuffer

    local BitsPerChar = mthlog(Base, 2)

    if (BitsPerChar % 1 == 0) then
        -- This should be re-worked later to wrap around the write and read functions to
        -- encode it without copying anything, which should be faster overall. For now this
        -- is enough.
        Result.GetClippedBuffer = function()
            dbgprofilebegin("BaseNEncode")

            local BitsLength = GetPosition()
            local RawBuffer = GetBuffer()
            local New = bufcreate(mthceil(BitsLength / BitsPerChar))

            local Accumulation = 0

            while (Accumulation < BitsLength) do
                local Bits = mthmin(BitsPerChar, BitsLength - Accumulation)
                bufwriteu8(New, Accumulation // BitsPerChar, bufreadu8(BaseCharacters, bufreadbits(RawBuffer, Accumulation, Bits)))
                Accumulation += Bits
            end

            dbgprofileend()
            return New
        end

        Result.SetBuffer = function(EncodedBuffer, From, To)
            dbgprofilebegin("BaseNDecode")

            local BitsLength = (From and (To - From) or buflen(EncodedBuffer) * 8)
            local RawBuffer = bufcreate(mthceil(BitsLength * 8 / BitsPerChar))

            -- Buffer has to be full of whole 8-bit characters, sub-byte lengths wouldn't make sense.
            for Index = 0, BitsLength // 8 - 1 do
                bufwritebits(RawBuffer, Index * BitsPerChar, BitsPerChar, ReverseBaseCharacters[bufreadu8(EncodedBuffer, Index) + 1])
            end

            SetBuffer(RawBuffer)
            dbgprofileend()
        end
    else
        error("BaseNSerializer only supports bases which are powers of 2 for performance reasons.")
    end

    return Result
end

return BaseNSerializer