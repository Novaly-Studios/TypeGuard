local Template = require(script.Parent:WaitForChild("_Template"))
    type TypeCheckerConstructor<T, P...> = Template.TypeCheckerConstructor<T, P...>
    type TypeChecker<ExtensionClass, Primitive> = Template.TypeChecker<ExtensionClass, Primitive>
    type SelfReturn<T, P...> = Template.SelfReturn<T, P...>

local Util = require(script.Parent.Parent:WaitForChild("Util"))
    local CreateStandardInitial = Util.CreateStandardInitial
    local ExpectType = Util.ExpectType
    local Expect = Util.Expect

type StringTypeChecker = TypeChecker<StringTypeChecker, string> & {
    MinLength: SelfReturn<StringTypeChecker, number | (any?) -> number>;
    MaxLength: SelfReturn<StringTypeChecker, number | (any?) -> number>;
    Contains: SelfReturn<StringTypeChecker, string | (any?) -> string>;
    Pattern: SelfReturn<StringTypeChecker, string | (any?) -> string>;
};

local String: TypeCheckerConstructor<StringTypeChecker, ...string?>, StringClass = Template.Create("String")
StringClass._Initial = CreateStandardInitial("string")

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

return String