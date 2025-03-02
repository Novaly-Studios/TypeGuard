--!native
--!optimize 2

if (not script) then
    script = game:GetService("ReplicatedFirst").TypeGuard.Core.String
end

local Template = require(script.Parent.Parent._Template)
    type TypeCheckerConstructor<T, P...> = Template.TypeCheckerConstructor<T, P...>
    type FunctionalArg<T> = Template.FunctionalArg<T>
    type TypeChecker<ExtensionClass, Primitive> = Template.TypeChecker<ExtensionClass, Primitive>
    type SelfReturn<T, P...> = Template.SelfReturn<T, P...>

local Util = require(script.Parent.Parent.Util)
    local CreateStandardInitial = Util.CreateStandardInitial
    local ByteSerializer = Util.ByteSerializer
    local ExpectType = Util.ExpectType
    local Expect = Util.Expect

local TableUtil = require(script.Parent.Parent.Parent.TableUtil).WithFeatures()

local Number = require(script.Parent.Number)

type StringTypeChecker = TypeChecker<StringTypeChecker, string> & {
    UsingCharacters: ((StringTypeChecker, CharacterSet: FunctionalArg<string?>) -> (StringTypeChecker));
    NullTerminated: ((self: StringTypeChecker) -> (StringTypeChecker));
    MinLength: ((StringTypeChecker, MinLength: FunctionalArg<number>) -> (StringTypeChecker));
    MaxLength: ((StringTypeChecker, MaxLength: FunctionalArg<number>) -> (StringTypeChecker));
    Contains: ((StringTypeChecker, Search: FunctionalArg<string>) -> (StringTypeChecker));
    Pattern: ((StringTypeChecker, Pattern: FunctionalArg<string>) -> (StringTypeChecker));
    IsUTF8: SelfReturn<StringTypeChecker, string | (any?) -> boolean>;
};

local String: ((PossibleValue: FunctionalArg<string?>, ...FunctionalArg<string?>) -> (StringTypeChecker)), StringClass = Template.Create("String")
StringClass._Initial = CreateStandardInitial("string")
StringClass._TypeOf = {"string"}

--- Ensures a string is at least a certain length.
function StringClass:MinLength(MinLength)
    ExpectType(MinLength, Expect.NUMBER_OR_FUNCTION, 1)

    return self:_AddConstraint(true, "MinLength", function(_, Item, MinLength)
        if (#Item < MinLength) then
            return false, `Length must be at least {MinLength}, got {#Item}`
        end

        return true
    end, MinLength)
end

--- Ensures a string is at most a certain length.
function StringClass:MaxLength(MaxLength)
    ExpectType(MaxLength, Expect.NUMBER_OR_FUNCTION, 1)

    return self:_AddConstraint(true, "MaxLength", function(_, Item, MaxLength)
        if (#Item > MaxLength) then
            return false, `Length must be at most {MaxLength}, got {#Item}`
        end

        return true
    end, MaxLength)
end

--- Ensures a string matches a pattern.
function StringClass:Pattern(PatternString)
    ExpectType(PatternString, Expect.STRING_OR_FUNCTION, 1)

    return self:_AddConstraint(false, "Pattern", function(_, Item, Pattern)
        if (string.match(Item, Pattern) == Item) then
            return true
        end

        return false, `String does not match pattern {Pattern}`
    end, PatternString)
end

--- Ensures a string is valid UTF-8.
function StringClass:IsUTF8()
    return self:_AddConstraint(true, "IsUTF8", function(_, Item)
        if (utf8.len(Item) ~= nil) then
            return true
        end

        return false, "String is not valid UTF-8"
    end)
end

--- Ensures a string contains a certain substring.
function StringClass:Contains(SubstringValue)
    ExpectType(SubstringValue, Expect.STRING_OR_FUNCTION, 1)

    return self:_AddConstraint(false, "Contains", function(_, Item, Substring)
        if (string.match(Item, Substring)) then
            return true
        end

        return false, `String does not contain substring {Substring}`
    end, SubstringValue)
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

    return self:_AddConstraint(true, "UsingCharacters", function(_, Item, CharacterSet, Match)
        if (string.match(Item, Match)) then
            return true
        end

        return false, `String does not match possible character set ({CharacterSet})`
    end, CharacterSet, Match)
end

--- Signifies the string is null-terminated.
function StringClass:NullTerminated()
    return self:_AddConstraint(true, "NullTerminated", function(_, Item)
        if (Item:match("\0") == nil) then
            return true
        end

        return false, "String contained a null-terminator and it should not for security, serialization will automatically add this"
    end)
end

--[[ local GUIDDashPattern = "%x%x%x%x%x%x%x%x-%x%x%x%x-%x%x%x%x-%x%x%x%x-%x%x%x%x%x%x%x%x%x%x%x%x"
local GUIDNoDashPattern = "%x%x%x%x%x%x%x%x%x%x%x%x%x%x%x%x%x%x%x%x%x%x%x%x%x%x%x%x%x%x%x%x"
function StringClass:GUID(Dashes: boolean?)
    if (Dashes ~= nil) then
        ExpectType(Dashes, Expect.BOOLEAN, 1)
    end

    return self:_AddConstraint(true, "GUID", function(_, Item, Dashes)
        local Length = #Item
        if (Length ~= 32 and Length ~= 36) then
            return false, "String is not a valid GUID"
        end

        if (Item:lower():match(Dashes and GUIDDashPattern or GUIDNoDashPattern)) then
            return true
        end

        return false, "String is not a valid GUID"
    end, Dashes)
end ]]

-- This can be optimized with custom implementation using arg select.
local IsAValueIn = Template.BaseMethods.IsAValueIn
StringClass.InitialConstraintsDirectVariadic = function(self, ...)
    return IsAValueIn(self, {...})
end

local DynamicUInt = Number():Positive():Integer():Dynamic() -- Number(0, 2^16-1):Integer()
    local DynamicUIntDeserialize = DynamicUInt._Deserialize
    local DynamicUIntSerialize = DynamicUInt._Serialize

local function TryCache(Buffer, Value, Cache)
    if (Cache) then
        DynamicUIntSerialize(Buffer, Cache(Value))
        return true
    end

    return false
end

local function TryDecache(Buffer, Cache)
    if (Cache) then
        return Cache[DynamicUIntDeserialize(Buffer)]
    end

    return nil
end

function StringClass:_UpdateSerialize()
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
            _Serialize = function(Buffer, Value, Cache)
                Value = Value:lower():gsub("%-", ""):gsub("%x%x", function(Pair)
                    return string.char(tonumber(Pair, 16) :: number)
                end)
                if (TryCache(Buffer, Value, Cache)) then
                    return
                end
                Buffer.WriteString(Value, #Value * 8)
            end;
            _Deserialize = function(Buffer, Cache)
                return Dashify(TryDecache(Buffer, Cache) or Buffer.ReadString(16)):gsub(".", function(Char)
                    return string.format("%02x", Char:byte())
                end)
            end;
        }
    end ]]

    local UsingCharacters = self:GetConstraint("UsingCharacters")
    if (UsingCharacters) then
        local CharacterSet = UsingCharacters[1]
        local Bits = math.ceil(math.log(#CharacterSet + 1, 2))
        local IndexToCharacter = CharacterSet:split("")
        local IndexToCharacterByte = TableUtil.Map.Map(IndexToCharacter, function(Character, Index)
            return string.byte(Character)
        end)
        local CharacterToIndex = TableUtil.Map.Map(IndexToCharacter, function(Character, Index)
            return Index, Character
        end)
        local Serializer = Number(0, 2^16-1):Integer()
            local SizeDeserialize = Serializer._Deserialize
            local SizeSerialize = Serializer._Serialize

        return {
            _Serialize = function(Buffer, Value, Cache)
                SizeSerialize(Buffer, #Value, Cache)

                local WriteUInt = Buffer.WriteUInt
                for Character in Value:gmatch(".") do
                    WriteUInt(Bits, CharacterToIndex[Character])
                end
            end;
            _Deserialize = function(Buffer, Cache)
                local Size = SizeDeserialize(Buffer, Cache)
                local Result = buffer.create(Size)
                local ReadUInt = Buffer.ReadUInt

                for Index = 0, Size - 1 do
                    buffer.writeu8(Result, Index, IndexToCharacterByte[ReadUInt(Bits)])
                end

                return buffer.tostring(Result)
            end;
        }
    end

    local NullTerminated = self:GetConstraint("NullTerminated")
    if (NullTerminated) then
        return {
            _Serialize = function(Buffer, Value, Cache)
                Buffer.WriteString(Value, #Value * 8)
                Buffer.WriteUInt(1, 0)
            end;
            _Deserialize = function(Buffer, Cache)
                local Result = ByteSerializer()
                local LastChar
                local ReadUInt = Buffer.ReadUInt
                local WriteUInt = Result.WriteUInt

                while (LastChar ~= 0) do
                    LastChar = ReadUInt(8)
                    WriteUInt(8, LastChar)
                end

                return buffer.tostring(Result.GetClippedBuffer())
            end;
        }
    end

    local MaxLength = self:GetConstraint("MaxLength")
    local MinLength = self:GetConstraint("MinLength")

    if (MaxLength and MinLength) then
        local MaxLengthValue = MaxLength[1]
        local MinLengthValue = MinLength[1]

        -- Length equals a certain value.
        if (MaxLengthValue == MinLengthValue) then
            return {
                _Serialize = function(Buffer, Value, Cache)
                    if (TryCache(Buffer, Value, Cache)) then
                        return
                    end
                    Buffer.WriteString(Value, #Value * 8)
                end;
                _Deserialize = function(Buffer, Cache)
                    return (TryDecache(Buffer, Cache) or Buffer.ReadString(MaxLengthValue * 8))
                end;
            }
        end

        -- Length is between a certain range.
        local Serializer = Number(MinLengthValue, MaxLengthValue):Integer()
            local NumberDeserialize = Serializer._Deserialize
            local NumberSerialize = Serializer._Serialize

        return {
            _Serialize = function(Buffer, Value, Cache)
                if (TryCache(Buffer, Value, Cache)) then
                    return
                end

                local Length = #Value
                NumberSerialize(Buffer, Length, Cache)
                Buffer.WriteString(Value, Length * 8)
            end;
            _Deserialize = function(Buffer, Cache)
                return (TryDecache(Buffer, Cache) or Buffer.ReadString(NumberDeserialize(Buffer, Cache) * 8))
            end;
        }
    end

    -- Last resort: dynamic length string.
    return {
        _Serialize = function(Buffer, Value, Cache)
            if (TryCache(Buffer, Value, Cache)) then
                return
            end

            local Length = #Value
            DynamicUIntSerialize(Buffer, Length)
            Buffer.WriteString(Value, Length * 8)
        end;
        _Deserialize = function(Buffer, Cache)
            return TryDecache(Buffer, Cache) or Buffer.ReadString(DynamicUIntDeserialize(Buffer) * 8)
        end;
    }
end

return String