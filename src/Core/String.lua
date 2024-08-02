--!native
--!optimize 2

if (not script) then
    script = game:GetService("ReplicatedFirst").TypeGuard.Core.String
end

local Template = require(script.Parent.Parent:WaitForChild("_Template"))
    type TypeCheckerConstructor<T, P...> = Template.TypeCheckerConstructor<T, P...>
    type FunctionalArg<T> = Template.FunctionalArg<T>
    type TypeChecker<ExtensionClass, Primitive> = Template.TypeChecker<ExtensionClass, Primitive>
    type SelfReturn<T, P...> = Template.SelfReturn<T, P...>

local Util = require(script.Parent.Parent.Util)
    local CreateStandardInitial = Util.CreateStandardInitial
    local ExpectType = Util.ExpectType
    local Expect = Util.Expect

local Number = require(script.Parent.Number)

type StringTypeChecker = TypeChecker<StringTypeChecker, string> & {
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

-- This can be optimized with custom implementation using arg select.
local IsAValueIn = Template.BaseMethods.IsAValueIn
StringClass.InitialConstraintsDirectVariadic = function(self, ...)
    return IsAValueIn(self, {...})
end

local DynamicUInt = Number(0, 0b1111111111111111):Integer()
    local DynamicUIntDeserialize = DynamicUInt._Deserialize
    local DynamicUIntSerialize = DynamicUInt._Serialize

function StringClass:_UpdateSerialize()
    -- TODO: contains can substitute all the found strings to empty & record positions at the start of the string.
    -- Same with pattern?

    local MaxLength = self:GetConstraint("MaxLength")
    local MinLength = self:GetConstraint("MinLength")

    if (MaxLength and MinLength) then
        local MaxLengthValue = MaxLength[1]
        local MinLengthValue = MinLength[1]

        -- Length equals a certain value.
        if (MaxLengthValue == MinLengthValue) then
            self._Serialize = function(Buffer, Value, _Cache)
                Buffer.WriteString(Value)
            end
            self._Deserialize = function(Buffer, _Cache)
                return Buffer.ReadString(MaxLengthValue * 8)
            end
            return
        end

        -- Length is between a certain range.
        local Serializer = Number(MinLengthValue, MaxLengthValue):Integer()
            local NumberDeserialize = Serializer._Deserialize
            local NumberSerialize = Serializer._Serialize

        self._Serialize = function(Buffer, Value, Cache)
            NumberSerialize(Buffer, #Value, Cache)
            Buffer.WriteString(Value)
        end
        self._Deserialize = function(Buffer, Cache)
            return Buffer.ReadString(NumberDeserialize(Buffer, Cache) * 8)
        end

        return
    end

    -- Last resort: dynamic length string.
    self._Serialize = function(Buffer, Value, Cache)
        if (Cache) then
            DynamicUIntSerialize(Buffer, Cache(Value))
            return
        end
        DynamicUIntSerialize(Buffer, #Value)
        Buffer.WriteString(Value)
    end
    self._Deserialize = function(Buffer, Cache)
        if (Cache) then
            return Cache[DynamicUIntDeserialize(Buffer)]
        end
        return Buffer.ReadString(DynamicUIntDeserialize(Buffer) * 8)
    end
end

return String