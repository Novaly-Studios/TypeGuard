--!native
--!optimize 2

if (not script and Instance) then
    script = game:GetService("ReplicatedFirst").TypeGuard.Core.String
end

local Template = require(script.Parent.Parent._Template)
    type TypeCheckerConstructor<T, P...> = Template.TypeCheckerConstructor<T, P...>
    type FunctionalArg<T> = Template.FunctionalArg<T>
    type TypeChecker<ExtensionClass, Primitive> = Template.TypeChecker<ExtensionClass, Primitive>

local Util = require(script.Parent.Parent.Util)
    local CreateStandardInitial = Util.CreateStandardInitial
    local ByteSerializer = Util.Serializers.Byte
    local ExpectType = Util.ExpectType
    local Expect = Util.Expect

local TableUtil = require(script.Parent.Parent.Parent.TableUtil).WithFeatures()

local Number = require(script.Parent.Number)

local b32lshift = bit32.lshift
local strbyte = string.byte

local buftostring = buffer.tostring
local bufwriteu8 = buffer.writeu8
local bufcreate = buffer.create

type StringTypeChecker = TypeChecker<StringTypeChecker, string> & {
    UsingCharacters: ((self: StringTypeChecker, CharacterSet: FunctionalArg<string?>) -> (StringTypeChecker));
    NullTerminated: ((self: StringTypeChecker) -> (StringTypeChecker));
    MinLength: ((self: StringTypeChecker, MinLength: FunctionalArg<number>) -> (StringTypeChecker));
    MaxLength: ((self: StringTypeChecker, MaxLength: FunctionalArg<number>) -> (StringTypeChecker));
    Contains: ((self: StringTypeChecker, Search: FunctionalArg<string>) -> (StringTypeChecker));
    Pattern: ((self: StringTypeChecker, Pattern: FunctionalArg<string>) -> (StringTypeChecker));
    Aligned: ((self: StringTypeChecker) -> (StringTypeChecker));
    IsUTF8: ((self: StringTypeChecker) -> (StringTypeChecker));
};

local String: ((PossibleValue: FunctionalArg<string?>, ...FunctionalArg<string?>) -> (StringTypeChecker)), StringClass = Template.Create("String")
StringClass._Initial = CreateStandardInitial("string")
StringClass._TypeOf = {"string"}

local function _MinLength(_, Item, _, MinLength)
    if (#Item < MinLength) then
        return false, `Length must be at least {MinLength}, got {#Item}`
    end

    return true
end

--- Ensures a string is at least a certain length.
function StringClass:MinLength(MinLength)
    ExpectType(MinLength, Expect.NUMBER_OR_FUNCTION, 1)

    return self:_AddConstraint(true, "MinLength", _MinLength, MinLength)
end

local function _MaxLength(_, Item, _, MaxLength)
    if (#Item > MaxLength) then
        return false, `Length must be at most {MaxLength}, got {#Item}`
    end

    return true
end

--- Ensures a string is at most a certain length.
function StringClass:MaxLength(MaxLength)
    ExpectType(MaxLength, Expect.NUMBER_OR_FUNCTION, 1)

    return self:_AddConstraint(true, "MaxLength", _MaxLength, MaxLength)
end

local function _Pattern(_, Item, _, Pattern)
    if (string.match(Item, Pattern) == Item) then
        return true
    end

    return false, `String does not match pattern {Pattern}`
end

--- Ensures a string matches a pattern.
function StringClass:Pattern(PatternString)
    ExpectType(PatternString, Expect.STRING_OR_FUNCTION, 1)

    return self:_AddConstraint(false, "Pattern", _Pattern, PatternString)
end

local function _IsUTF8(_, Item, _)
    if (utf8.len(Item) ~= nil) then
        return true
    end

    return false, "String is not valid UTF-8"
end

--- Ensures a string is valid UTF-8.
function StringClass:IsUTF8()
    return self:_AddConstraint(true, "IsUTF8", _IsUTF8)
end

local function _Contains(_, Item, _, Substring)
    if (string.match(Item, Substring)) then
        return true
    end

    return false, `String does not contain substring {Substring}`
end

--- Ensures a string contains a certain substring.
function StringClass:Contains(SubstringValue)
    ExpectType(SubstringValue, Expect.STRING_OR_FUNCTION, 1)

    return self:_AddConstraint(false, "Contains", _Contains, SubstringValue)
end

local function _UsingCharacters(_, Item, _, CharacterSet, Match)
    if (string.match(Item, Match)) then
        return true
    end

    return false, `String does not match possible character set ({CharacterSet})`
end

--- Narrows down the possible set of characters which can be used in a string.
--- Can help shorten string size if using a bit-level serializer.
function StringClass:UsingCharacters(CharacterSet: string?)
    if (CharacterSet) then
        ExpectType(CharacterSet, Expect.STRING, 1)
    else
        -- 63 characters for 6 bits per character in serialization.
        CharacterSet = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789_"
    end
    assert(#(CharacterSet :: string) > 0, "Character set must be at least one character long")

    local Match = `[{string.gsub(CharacterSet :: string, ".", function(Char)
        return `%{Char}`
    end)}]+`

    return self:_AddConstraint(true, "UsingCharacters", _UsingCharacters, CharacterSet, Match)
end

local function _NullTerminated(_, Item, _)
    if (Item:match("\0") == nil) then
        return true
    end

    return false, "String contained a null-terminator and it should not for security, serialization will automatically add this"
end

--- Signifies the string is null-terminated.
function StringClass:NullTerminated()
    return self:_AddConstraint(true, "NullTerminated", _NullTerminated)
end

--- Ensures the string is aligned to the nearest byte for fast writes (for BitSerializer).
function StringClass:Aligned()
    return self:Modify({
        _Aligned = true;
    })
end

--[[ local function _GUID(_, Item, Dashes)
    local Length = #Item
    if (Length ~= 32 and Length ~= 36) then
        return false, "String is not a valid GUID"
    end

    if (Item:lower():match(Dashes and GUIDDashPattern or GUIDNoDashPattern)) then
        return true
    end

    return false, "String is not a valid GUID"
end

local GUIDDashPattern = "%x%x%x%x%x%x%x%x-%x%x%x%x-%x%x%x%x-%x%x%x%x-%x%x%x%x%x%x%x%x%x%x%x%x"
local GUIDNoDashPattern = "%x%x%x%x%x%x%x%x%x%x%x%x%x%x%x%x%x%x%x%x%x%x%x%x%x%x%x%x%x%x%x%x"

function StringClass:GUID(Dashes: boolean?)
    if (Dashes ~= nil) then
        ExpectType(Dashes, Expect.BOOLEAN, 1)
    end

    return self:_AddConstraint(true, "GUID", _GUID, Dashes)
end ]]

-- This can be optimized with custom implementation using arg select.
local IsAValueIn = Template.BaseMethods.IsAValueIn
StringClass.InitialConstraintsDirectVariadic = function(self, ...)
    return IsAValueIn(self, {...})
end

local DynamicUInt = Number():Integer(32, false):Positive():Dynamic()
    local DynamicUIntDeserialize = DynamicUInt._Deserialize
    local DynamicUIntSerialize = DynamicUInt._Serialize

function StringClass:_Update()
    -- TODO: contains can substitute all the found strings to empty & record positions at the start of the string.
    -- Same with pattern?

    --[[ local GUID = self:GetConstraint("GUID")
    if (GUID) then
        local Dashes = GUID[1]
        local function Dashify(GUID: string)
            if (Dashes) then
                return `{GUID:sub(1, 8)}-{GUID:sub(9, 12)}-{GUID:sub(13, 16)}-{GUID:sub(17, 20)}-{GUID:sub(21, 32)}`
            end
            return GUID
        end

        return {
            _Serialize = function(Buffer, Value, Context)
                local BufferContext = Buffer.Context

                if (BufferContext) then
                    BufferContext("String(GUID)")
                end

                Value = Value:lower():gsub("%-", ""):gsub("%x%x", function(Pair)
                    return string.char(tonumber(Pair, 16) :: number)
                end)

                if (TryCache(Buffer, Value, Context)) then
                    return
                end

                Buffer.WriteString(Value, #Value * 8)

                if (BufferContext) then
                    BufferContext()
                end
            end;
            _Deserialize = function(Buffer, Context)
                return Dashify(TryDecache(Buffer, Context) or Buffer.ReadString(16)):gsub(".", function(Char)
                    return string.format("%02x", Char:byte())
                end)
            end;
        }
    end ]]

    local MinLength = self:GetConstraint("MinLength")
        local MinLengthValue = (MinLength and MinLength[1] or nil)

    local MaxLength = self:GetConstraint("MaxLength")
        local MaxLengthValue = (MaxLength and MaxLength[1] or nil)

    local Aligned = self._Aligned
    local UsingCharacters = self:GetConstraint("UsingCharacters")

    if (UsingCharacters) then
        local CharacterSet = UsingCharacters[1]
        local IndexToCharacter = CharacterSet:split("")
        local Bits = math.ceil(math.log(#CharacterSet + 1, 2))

        local IndexToCharacterByte = TableUtil.Map.Map(IndexToCharacter, function(Character, Index)
            return string.byte(Character)
        end)

        local CharacterToIndex = TableUtil.Map.Map(IndexToCharacter, function(Character, Index)
            return Index, Character
        end)

        return {
            _Serialize = function(Buffer, Value, Context)
                local BufferContext = Buffer.Context

                if (BufferContext) then
                    BufferContext("String(UsingCharacters)")
                end

                local WriteUInt = Buffer.WriteUInt
                DynamicUIntSerialize(Buffer, #Value, Context)

                for Character in Value:gmatch(".") do
                    WriteUInt(Bits, CharacterToIndex[Character])
                end

                --[[ for Index = 1, #Value, 4 do
                    local Char1, Char2, Char3, Char4 = strbyte(String, Index, Index + 3)

                    if (Char4) then
                        WriteUInt(32, b32lshift(Char4, 24) + b32lshift(Char3, 16) + b32lshift(Char2, 8) + Char1)
                        continue
                    end

                    if (Char3) then
                        WriteUInt(24, b32lshift(Char3, 16) + b32lshift(Char2, 8) + Char1)
                        continue
                    end

                    if (Char2) then
                        WriteUInt(16, b32lshift(Char2, 8) + Char1)
                        continue
                    end

                    WriteUInt(8, Char1)
                end ]]

                if (BufferContext) then
                    BufferContext()
                end
            end;
            _Deserialize = function(Buffer, Context)
                local Size = DynamicUIntDeserialize(Buffer, Context)
                local Result = bufcreate(Size)
                local ReadUInt = Buffer.ReadUInt

                for Index = 0, Size - 1 do
                    bufwriteu8(Result, Index, IndexToCharacterByte[ReadUInt(Bits)])
                end

                return buftostring(Result)
            end;
            _Sample = function(Context, _Depth)
                local Random = Context.Random
                local Result = buffer.create(Random:NextInteger(MinLengthValue or 0, math.max(MinLengthValue or 0, MaxLengthValue or 64)))

                for Index = 0, buffer.len(Result) - 1 do
                    buffer.writeu8(Result, Index, IndexToCharacterByte[Random:NextInteger(1, #IndexToCharacterByte)])
                end

                return buffer.tostring(Result)
            end;
        }
    end

    local NullTerminated = self:GetConstraint("NullTerminated")

    if (NullTerminated) then
        return {
            _Serialize = function(Buffer, Value, _Context)
                local BufferContext = Buffer.Context

                if (BufferContext) then
                    BufferContext("String(NullTerminated)")
                end

                if (Aligned) then
                    Buffer.Align()
                end

                Buffer.WriteString(Value, #Value * 8)
                Buffer.WriteUInt(1, 0)

                if (BufferContext) then
                    BufferContext()
                end
            end;
            _Deserialize = function(Buffer, _Context)
                local Result = ByteSerializer()
                local LastChar
                local ReadUInt = Buffer.ReadUInt
                local WriteUInt = Result.WriteUInt

                if (Aligned) then
                    Buffer.Align()
                end

                -- Needs optimization.
                while (LastChar ~= 0) do
                    LastChar = ReadUInt(8)
                    WriteUInt(8, LastChar)
                end

                return buffer.tostring(Result.GetClippedBuffer())
            end;
            _Sample = function(Context, _Depth)
                local Random = Context.Random
                local Result = buffer.create(Random:NextInteger(MinLengthValue or 0, math.max(MinLengthValue or 0, MaxLengthValue or 64)))

                for Index = 0, buffer.len(Result) - 2 do
                    buffer.writeu8(Result, Index, Random:NextInteger(1, 255))
                end

                buffer.writeu8(Result, buffer.len(Result) - 1, 0)
                return buffer.tostring(Result)
            end;
        }
    end

    if (MaxLength and MinLength) then
        -- Length equals a certain value.
        if (MaxLengthValue == MinLengthValue) then
            return {
                _Serialize = function(Buffer, Value, _Context)
                    local BufferContext = Buffer.Context

                    if (BufferContext) then
                        BufferContext("String(FixedLength)")
                    end

                    if (Aligned) then
                        Buffer.Align()
                    end

                    Buffer.WriteString(Value, #Value * 8)

                    if (BufferContext) then
                        BufferContext()
                    end
                end;
                _Deserialize = function(Buffer, _Context)
                    if (Aligned) then
                        Buffer.Align()
                    end

                    return Buffer.ReadString(MaxLengthValue * 8)
                end;
                _Sample = function(Context, _Depth)
                    local Random = Context.Random
                    local Result = buffer.create(MaxLengthValue)

                    for Index = 0, buffer.len(Result) - 1 do
                        buffer.writeu8(Result, Index, Random:NextInteger(0, 255))
                    end

                    return buffer.tostring(Result)
                end;
            }
        end

        -- Length is between a certain range.
        local Serializer = Number(MinLengthValue, MaxLengthValue):Integer()
            local NumberDeserialize = Serializer._Deserialize
            local NumberSerialize = Serializer._Serialize

        return {
            _Serialize = function(Buffer, Value, Context)
                local BufferContext = Buffer.Context

                if (BufferContext) then
                    BufferContext("String(MinLength, MaxLength)")
                end

                local Length = #Value
                NumberSerialize(Buffer, Length, Context)

                if (Aligned) then
                    Buffer.Align()
                end

                Buffer.WriteString(Value, Length * 8)

                if (BufferContext) then
                    BufferContext()
                end
            end;
            _Deserialize = function(Buffer, Context)
                local Length = NumberDeserialize(Buffer, Context) * 8

                if (Aligned) then
                    Buffer.Align()
                end

                return Buffer.ReadString(Length)
            end;
            _Sample = function(Context, _Depth)
                local Random = Context.Random
                local Result = buffer.create(Random:NextInteger(MinLengthValue, MaxLengthValue))

                for Index = 0, buffer.len(Result) - 1 do
                    buffer.writeu8(Result, Index, Random:NextInteger(0, 255))
                end

                return buffer.tostring(Result)
            end;
        }
    end

    -- Last resort: dynamic length string.
    return {
        _Serialize = function(Buffer, Value, Context)
            local BufferContext = Buffer.Context

            if (BufferContext) then
                BufferContext("String(DynamicLength)")
            end

            local Length = #Value
            DynamicUIntSerialize(Buffer, Length)

            if (Aligned) then
                Buffer.Align()
            end

            Buffer.WriteString(Value, Length * 8)

            if (BufferContext) then
                BufferContext()
            end
        end;
        _Deserialize = function(Buffer, Context)
            local Length = DynamicUIntDeserialize(Buffer) * 8

            if (Aligned) then
                Buffer.Align()
            end

            return Buffer.ReadString(Length)
        end;
        _Sample = function(Context, _Depth)
            local Random = Context.Random
            local Result = buffer.create(Random:NextInteger(MinLengthValue or 0, math.max(MinLengthValue or 0, MaxLengthValue or 64)))

            for Index = 0, buffer.len(Result) - 1 do
                buffer.writeu8(Result, Index, Random:NextInteger(0, 255))
            end

            return buffer.tostring(Result)
        end;
    }
end

return String