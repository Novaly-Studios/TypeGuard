-- @TODO This script really needs splitting up into sub-modules

local EMPTY_STRING = ""
local INVALID_ARGUMENT = "Invalid argument #%s (%s expected, got %s)"

--- This is only really for type checking internally for data passed to constraints and util functions
local function ExpectType<T>(PassedArg: T, ExpectedType: string, ArgKey: number | string)
    local GotType = typeof(PassedArg)
    assert(GotType == ExpectedType, INVALID_ARGUMENT:format(tostring(ArgKey), ExpectedType, GotType))
end

local function CreateStandardInitial(ExpectedTypeName: string): ((...any) -> (boolean, string))
    return function(_, Item)
        local ItemType = typeof(Item)

        if (ItemType == ExpectedTypeName) then
            return true, EMPTY_STRING
        end

        return false, "Expected " .. ExpectedTypeName .. ", got " .. ItemType
    end
end

local function ConcatWithToString<T>(Array: {T}, Separator: string): string
    local Result = EMPTY_STRING
    local Size = #Array

    for Index, Value in ipairs(Array) do
        Result ..= tostring(Value)

        if (Index < Size) then
            Result ..= Separator
        end
    end

    return Result
end

local STRUCTURE_TO_FLAT_STRING_MT = {
    __tostring = function(self)
        local Pairings = {}

        for Key, Value in pairs(self) do
            table.insert(Pairings, tostring(Key) .. " = " .. tostring(Value))
        end

        return "{" .. ConcatWithToString(Pairings, ", ") .. "}"
    end;
}

-- Standard re-usable functions throughout all type checkers
    local function IsAKeyIn(self, Store)
        ExpectType(Store, "table", 1)

        return self:_AddConstraint("IsAKeyIn", function(_, Key, Store)
            return Store[Key] ~= nil, "No key found in table: " .. tostring(Store)
        end, Store)
    end

    local function IsAValueIn(self, Store)
        ExpectType(Store, "table", 1)

        return self:_AddConstraint("IsAValueIn", function(_, TargetValue, Store)
            for _, Value in pairs(Store) do
                if (Value == TargetValue) then
                    return true, EMPTY_STRING
                end
            end

            return false, "No value found in table: " .. tostring(Store)
        end, Store)
    end

    local function Equals(self, ExpectedValue)
        return self:_AddConstraint("Equals", function(_, Value, ExpectedValue)
            return Value == ExpectedValue, "Value " .. tostring(Value) .. " does not equal " .. tostring(ExpectedValue)
        end, ExpectedValue)
    end

    local function GreaterThan(self, GTValue)
        return self:_AddConstraint("GreaterThan", function(_, Value, GTValue)
            return Value > GTValue, "Value " .. tostring(Value) .. " is not greater than " .. tostring(GTValue)
        end, GTValue)
    end

    local function LessThan(self, LTValue)
        return self:_AddConstraint("LessThan", function(_, Value, LTValue)
            return Value < LTValue, "Value " .. tostring(Value) .. " is not less than " .. tostring(LTValue)
        end, LTValue)
    end

    local function GreaterThanOrEqualTo(self, GTEValue)
        return self:_AddConstraint("GreaterThanOrEqualTo", function(_, Value, GTEValue)
            return Value >= GTEValue, "Value " .. tostring(Value) .. " is not greater than or equal to " .. tostring(GTEValue)
        end, GTEValue)
    end

    local function LessThanOrEqualTo(self, LTEValue)
        return self:_AddConstraint("LessThanOrEqualTo", function(_, Value, LTEValue)
            return Value <= LTEValue, "Value " .. tostring(Value) .. " is not less than or equal to " .. tostring(LTEValue)
        end, LTEValue)
    end




type SelfReturn<T, P...> = ((T, P...) -> T)

type TypeCheckerConstructor<T, P...> = ((P...) -> T)

type TypeChecker<T> = {
    Or: SelfReturn<T, TypeChecker<any>>;
    And: SelfReturn<T, TypeChecker<any>>;
    Alias: SelfReturn<T, string>;
    AddTag: SelfReturn<T, string>;
    Optional: SelfReturn<T>;

    WrapCheck: (T) -> ((any) -> (boolean, string));
    WrapAssert: (T) -> ((any) -> ());
    Check: (T, any) -> (string, boolean);
    Assert: (T, any) -> ();

    -- Standard constraints
    Equals: SelfReturn<T, any>;
    equals: SelfReturn<T, any>;

    IsAValueIn: SelfReturn<T, any>;
    isAValueIn: SelfReturn<T, any>;

    IsAKeyIn: SelfReturn<T, any>;
    isAKeyIn: SelfReturn<T, any>;

    GreaterThan: SelfReturn<T, number>;
    greaterThan: SelfReturn<T, number>;

    LessThan: SelfReturn<T, number>;
    lessThan: SelfReturn<T, number>;

    GreaterThanOrEqualTo: SelfReturn<T, number>;
    greaterThanOrEqualTo: SelfReturn<T, number>;

    LessThanOrEqualTo: SelfReturn<T, number>;
    lessThanOrEqualTo: SelfReturn<T, number>;
};

local TypeGuard = {}

function TypeGuard.Template(Name: string)
    ExpectType(Name, "string", 1)

    local TemplateClass = {}
    TemplateClass.__index = TemplateClass
    TemplateClass._IsTemplate = true
    TemplateClass._InitialConstraint = nil
    TemplateClass._Type = Name

    function TemplateClass.new(...)
        local self = {
            _Tags = {};
            _Disjunction = {};
            _Conjunction = {};
            _ActiveConstraints = {};
        }

        setmetatable(self, TemplateClass)

        local NumArgs = select("#", ...)

        -- Support for a single constraint passed as the constructor, with an arbitrary number of args
        local InitialConstraint = self._InitialConstraint

        if (InitialConstraint and NumArgs > 0) then
            return InitialConstraint(self, ...)
        end

        -- Multiple constraints support (but only ONE arg per constraint is supported currently)
        local InitialConstraints = TemplateClass._InitialConstraints

        if (InitialConstraints and NumArgs > 0) then
            for Index = 1, NumArgs do
                self = InitialConstraints[Index](self, select(Index, ...))
            end

            return self
        end

        return self
    end

    function TemplateClass:_Copy()
        local New = TemplateClass.new()

        -- Copy tags
        for Key, Value in pairs(self._Tags) do
            New._Tags[Key] = Value
        end

        -- Copy OR
        for Index, Disjunction in ipairs(self._Disjunction) do
            New._Disjunction[Index] = Disjunction
        end

        -- Copy AND
        for Index, Conjunction in ipairs(self._Conjunction) do
            New._Conjunction[Index] = Conjunction
        end

        -- Copy constraints
        for ConstraintName, Constraint in pairs(self._ActiveConstraints) do
            New._ActiveConstraints[ConstraintName] = Constraint
        end

        return New
    end

    -- TODO: only 1 constraint of each type
    function TemplateClass:_AddConstraint(ConstraintName, Constraint, ...)
        ExpectType(ConstraintName, "string", 1)
        ExpectType(Constraint, "function", 2)

        self = self:_Copy()

        local ActiveConstraints = self._ActiveConstraints
        assert(ActiveConstraints[ConstraintName] == nil, "Constraint already exists: " .. ConstraintName)
        ActiveConstraints[ConstraintName] = {Constraint, {...}}
        return self
    end

    --- Calling this will only check the type of the passed value if that value is not nil, i.e. it's an optional value so nothing can be passed, but if it is not nothing then it will be checked
    function TemplateClass:Optional()
        return self:AddTag("Optional")
    end

    --- Enqueues a new constraint to satisfy 'or' i.e. "check x or check y or check z or ..." must pass
    function TemplateClass:Or(OtherType)
        TypeGuard._AssertIsTypeBase(OtherType, 1)

        self = self:_Copy()
        table.insert(self._Disjunction, OtherType)
        return self
    end

    --- Enqueues a new constraint to satisfy 'and' i.e. "check x and check y and check z and ..." must pass
    function TemplateClass:And(OtherType)
        TypeGuard._AssertIsTypeBase(OtherType, 1)

        self = self:_Copy()
        table.insert(self._Conjunction, OtherType)
        return self
    end

    --- Creates an Alias - useful for replacing large "Or" chains in big structures to identify where it is failing
    function TemplateClass:Alias(AliasName)
        ExpectType(AliasName, "string", 1)

        self = self:_Copy()
        self._Alias = AliasName
        return self
    end

    --- Adds a tag (for internal purposes)
    --- @todo Make this private?
    function TemplateClass:AddTag(TagName)
        ExpectType(TagName, "string", 1)

        assert(self._Tags[TagName] == nil, "Tag already exists: " .. TagName)

        self = self:_Copy()
        self._Tags[TagName] = true
        return self
    end

    --- Wrap Check into its own callable function
    function TemplateClass:WrapCheck()
        return function(Value)
            return self:Check(Value)
        end
    end

    --- Wraps Assert into its own callable function
    function TemplateClass:WrapAssert()
        return function(Value)
            return self:Assert(Value)
        end
    end

    --- Checks if the value is of the correct type
    function TemplateClass:Check(Value)
        -- Handle "type x or type y or type z ..."
        -- We do this before checking constraints to check if any of the other conditions succeed
        local Disjunctions = self._Disjunction
        local DidTryDisjunction = (Disjunctions[1] ~= nil)

        for _, AlternateType in ipairs(Disjunctions) do
            local Success, _ = AlternateType:Check(Value)

            if (Success) then
                return true, EMPTY_STRING
            end
        end

        -- Handle "type x and type y and type z ..." - this is only really useful for objects and arrays
        for _, Conjunction in ipairs(self._Conjunction) do
            local Success, Message = Conjunction:Check(Value)

            if (not Success) then
                return false, "[Conjunction " .. tostring(Conjunction) .. "] " .. Message
            end
        end

        -- Optional allows the value to be nil, in which case it won't be checked and we can resolve
        if (self._Tags.Optional and Value == nil) then
            return true, EMPTY_STRING
        end

        -- Handle initial type check
        local Success, Message = self:_Initial(Value)

        if (not Success) then
            if (DidTryDisjunction) then
                return false, "Disjunctions failed on " .. tostring(self)
            else
                return false, Message
            end
        end

        -- Handle active constraints
        for _, Constraint in pairs(self._ActiveConstraints) do
            local SubSuccess, SubMessage = Constraint[1](self, Value, unpack(Constraint[2]))

            if (not SubSuccess) then
                if (DidTryDisjunction) then
                    return false, "Disjunctions failed on " .. tostring(self)
                else
                    return false, SubMessage
                end
            end
        end

        return true, EMPTY_STRING
    end

    --- Throws an error if the check is unsatisfied
    function TemplateClass:Assert(Value)
        assert(self:Check(Value))
    end

    function TemplateClass:__tostring()
        -- User can create a unique alias to help simplify "where did it fail?"
        if (self._Alias) then
            return self._Alias
        end

        local Fields = {}

        -- Constraints list (including arg, possibly other type defs)
        if (next(self._ActiveConstraints) ~= nil) then
            local InnerConstraints = {}

            for ConstraintName, Constraint in pairs(self._ActiveConstraints) do
                table.insert(InnerConstraints, ConstraintName .. "(" .. ConcatWithToString(Constraint[2], ", ") .. ")")
            end

            table.insert(Fields, "Constraints = {" .. ConcatWithToString(InnerConstraints, ", ") .. "}")
        end

        -- Alternatives field str
        if (#self._Disjunction > 0) then
            local Alternatives = {}

            for _, AlternateType in ipairs(self._Disjunction) do
                table.insert(Alternatives, tostring(AlternateType))
            end

            table.insert(Fields, "Or = {" .. ConcatWithToString(Alternatives, ", ") .. "}")
        end

        -- Union fields str
        if (#self._Conjunction > 0) then
            local Unions = {}

            for _, Union in ipairs(self._Conjunction) do
                table.insert(Unions, tostring(Union))
            end

            table.insert(Fields, "And = {" .. ConcatWithToString(Unions, ", ") .. "}")
        end

        -- Tags (e.g. Optional, Strict)
        if (next(self._Tags) ~= nil) then
            local Tags = {}

            for Tag in pairs(self._Tags) do
                table.insert(Tags, Tag)
            end

            table.insert(Fields, "Tags = {" .. ConcatWithToString(Tags, ", ") .. "}")
        end

        return self._Type .. "(" .. ConcatWithToString(Fields, ", ") .. ")"
    end

    TemplateClass.Equals = Equals
    TemplateClass.equals = Equals

    TemplateClass.IsAValueIn = IsAValueIn
    TemplateClass.isAValueIn = IsAValueIn

    TemplateClass.IsAKeyIn = IsAKeyIn
    TemplateClass.isAKeyIn = IsAKeyIn

    TemplateClass.GreaterThan = GreaterThan
    TemplateClass.greaterThan = GreaterThan

    TemplateClass.LessThan = LessThan
    TemplateClass.lessThan = LessThan

    TemplateClass.GreaterThanOrEqualTo = GreaterThanOrEqualTo
    TemplateClass.greaterThanOrEqualTo = GreaterThanOrEqualTo

    TemplateClass.LessThanOrEqualTo = LessThanOrEqualTo
    TemplateClass.lessThanOrEqualTo = LessThanOrEqualTo

    return function(...)
        return TemplateClass.new(...)
    end, TemplateClass
end

--- Checks if an object contains the fields which define a type template from this module
function TypeGuard._AssertIsTypeBase<T>(Subject: T, Position: number | string)
    ExpectType(Subject, "table", Position)

    assert(Subject._IsTemplate, "Subject is not a type template")
end

--- Cheap & easy way to create a type without any constraints, and just an initial check corresponding to Roblox's typeof
function TypeGuard.FromTypeName(TypeName: string)
    ExpectType(TypeName, "string", 1)

    local CheckerFunction, CheckerClass = TypeGuard.Template(TypeName)
    CheckerClass._Initial = CreateStandardInitial(TypeName)

    type CustomTypeChecker = TypeChecker<CustomTypeChecker> & {}
    return CheckerFunction :: TypeCheckerConstructor<CustomTypeChecker>
end
TypeGuard.fromTypeName = TypeGuard.FromTypeName




do
    type NumberTypeChecker = TypeChecker<NumberTypeChecker> & {
        Integer: SelfReturn<NumberTypeChecker>;
        integer: SelfReturn<NumberTypeChecker>;

        Decimal: SelfReturn<NumberTypeChecker>;
        decimal: SelfReturn<NumberTypeChecker>;

        RangeInclusive: SelfReturn<NumberTypeChecker, number, number>;
        rangeInclusive: SelfReturn<NumberTypeChecker, number, number>;

        RangeExclusive: SelfReturn<NumberTypeChecker, number, number>;
        rangeExclusive: SelfReturn<NumberTypeChecker, number, number>;

        Positive: SelfReturn<NumberTypeChecker>;
        positive: SelfReturn<NumberTypeChecker>;

        Negative: SelfReturn<NumberTypeChecker>;
        negative: SelfReturn<NumberTypeChecker>;
    };

    local Number: TypeCheckerConstructor<NumberTypeChecker, TypeChecker<any>?>, NumberClass = TypeGuard.Template("Number")
    NumberClass._Initial = CreateStandardInitial("number")

    --- Checks if the value is whole
    function NumberClass:Integer()
        return self:_AddConstraint("Integer", function(_, Item)
            return math.floor(Item) == Item, "Expected integer form, got " .. tostring(Item)
        end)
    end
    NumberClass.integer = NumberClass.Integer

    --- Checks if the number is a decimal
    function NumberClass:Decimal()
        return self:_AddConstraint("Decimal", function(_, Item)
            return math.floor(Item) ~= Item, "Expected decimal form, got " .. tostring(Item)
        end)
    end
    NumberClass.decimal = NumberClass.Decimal

    --- Ensures a number is between or equal to a minimum and maxmimu value
    function NumberClass:RangeInclusive(Min, Max)
        ExpectType(Min, "number", 1)
        ExpectType(Max, "number", 2)

        return self:GreaterThanOrEqualTo(Min):LessThanOrEqualTo(Max)
    end
    NumberClass.rangeInclusive = NumberClass.RangeInclusive

    --- Ensures a number is between but not equal to a minimum and maximum value
    function NumberClass:RangeExclusive(Min, Max)
        return self:GreaterThan(Min):LessThan(Max)
    end
    NumberClass.rangeExclusive = NumberClass.RangeExclusive

    --- Checks the number is positive
    function NumberClass:Positive()
        return self:_AddConstraint("Positive", function(_, Item)
            if (Item < 0) then
                return false, "Expected positive number, got " .. tostring(Item)
            end

            return true, EMPTY_STRING
        end)
    end
    NumberClass.positive = NumberClass.Positive

    --- Checks the number is negative
    function NumberClass:Negative()
        return self:_AddConstraint("Negative", function(_, Item)
            if (Item >= 0) then
                return false, "Expected negative number, got " .. tostring(Item)
            end

            return true, EMPTY_STRING
        end)
    end
    NumberClass.negative = NumberClass.Negative

    TypeGuard.Number = Number
    TypeGuard.number = Number
end




do
    type StringTypeChecker = TypeChecker<StringTypeChecker> & {
        MinLength: SelfReturn<StringTypeChecker, number>;
        minLength: SelfReturn<StringTypeChecker, number>;

        MaxLength: SelfReturn<StringTypeChecker, number>;
        maxLength: SelfReturn<StringTypeChecker, number>;

        Pattern: SelfReturn<StringTypeChecker, string>;
        pattern: SelfReturn<StringTypeChecker, string>;
    };

    local String: TypeCheckerConstructor<StringTypeChecker, TypeChecker<any>?>, StringClass = TypeGuard.Template("String")
    StringClass._Initial = CreateStandardInitial("string")

    --- Ensures a string is at least a certain length
    function StringClass:MinLength(MinLength)
        ExpectType(MinLength, "number", 1)

        return self:_AddConstraint("MinLength", function(_, Item, MinLength)
            if (#Item < MinLength) then
                return false, "Length must be at least " .. MinLength .. ", got " .. #Item
            end

            return true, EMPTY_STRING
        end, MinLength)
    end
    StringClass.minLength = StringClass.MinLength

    --- Ensures a string is at most a certain length
    function StringClass:MaxLength(MaxLength)
        ExpectType(MaxLength, "number", 1)

        return self:_AddConstraint("MaxLength", function(_, Item, MaxLength)
            if (#Item > MaxLength) then
                return false, "Length must be at most " .. MaxLength .. ", got " .. #Item
            end

            return true, EMPTY_STRING
        end, MaxLength)
    end
    StringClass.maxLength = StringClass.MaxLength

    --- Ensures a string matches a pattern
    function StringClass:Pattern(PatternString)
        ExpectType(PatternString, "string", 1)

        return self:_AddConstraint("Pattern", function(_, Item, Pattern)
            if (string.match(Item, Pattern) ~= Item) then
                return false, "String does not match pattern " .. tostring(Pattern)
            end

            return true, EMPTY_STRING
        end, PatternString)
    end
    StringClass.pattern = StringClass.Pattern

    --- Ensures a string contains a certain substring
    function StringClass:Contains(SubstringValue)
        ExpectType(SubstringValue, "string", 1)

        return self:_AddConstraint("Contains", function(_, Item, Substring)
            if (string.find(Item, Substring) == nil) then
                return false, "String does not contain substring " .. tostring(Substring)
            end

            return true, EMPTY_STRING
        end, SubstringValue)
    end

    TypeGuard.String = String
    TypeGuard.string = String
end




do
    local PREFIX_ARRAY = "Index "
    local PREFIX_PARAM = "Param #"
    local ERR_PREFIX = "[%s%d] "
    local ERR_UNEXPECTED_VALUE = ERR_PREFIX .. " Unexpected value (strict tag is present)"

    type ArrayTypeChecker = TypeChecker<ArrayTypeChecker> & {
        OfLength: SelfReturn<ArrayTypeChecker, number>;
        ofLength: SelfReturn<ArrayTypeChecker, number>;

        MinLength: SelfReturn<ArrayTypeChecker, number>;
        minLength: SelfReturn<ArrayTypeChecker, number>;

        MaxLength: SelfReturn<ArrayTypeChecker, number>;
        maxLength: SelfReturn<ArrayTypeChecker, number>;

        Contains: SelfReturn<ArrayTypeChecker, any>;
        contains: SelfReturn<ArrayTypeChecker, any>;

        OfType: SelfReturn<ArrayTypeChecker, TypeChecker<any>>;
        ofType: SelfReturn<ArrayTypeChecker, TypeChecker<any>>;

        OfStructure: SelfReturn<ArrayTypeChecker, {TypeChecker<any>}>;
        ofStructure: SelfReturn<ArrayTypeChecker, {TypeChecker<any>}>;

        StructuralEquals: SelfReturn<ArrayTypeChecker, {TypeChecker<any>}>;
        structuralEquals: SelfReturn<ArrayTypeChecker, {TypeChecker<any>}>;

        Strict: SelfReturn<ArrayTypeChecker>;
        strict: SelfReturn<ArrayTypeChecker>;

        DenoteParams: SelfReturn<ArrayTypeChecker>;
        denoteParams: SelfReturn<ArrayTypeChecker>;
    };

    local Array: TypeCheckerConstructor<ArrayTypeChecker, TypeChecker<any>?>, ArrayClass = TypeGuard.Template("Array")

    function ArrayClass:_PrefixError(ErrorString: string, Index: number)
        return ErrorString:format((self._Tags.DenoteParams and PREFIX_PARAM or PREFIX_ARRAY), Index)
    end

    function ArrayClass:_Initial(TargetArray)
        if (typeof(TargetArray) ~= "table") then
            return false, "Expected table, got " .. typeof(TargetArray)
        end

        for Key in pairs(TargetArray) do
            local KeyType = typeof(Key)

            if (KeyType ~= "number") then
                return false, "Non-numetic key detected: " .. KeyType
            end
        end

        return true, EMPTY_STRING
    end

    --- Ensures an array is of a certain length
    function ArrayClass:OfLength(Length)
        ExpectType(Length, "number", 1)

        return self:_AddConstraint("Length", function(_, TargetArray, Length)
            if (#TargetArray ~= Length) then
                return false, "Length must be " .. Length .. ", got " .. #TargetArray
            end

            return true, EMPTY_STRING
        end, Length)
    end
    ArrayClass.ofLength = ArrayClass.OfLength

    --- Ensures an array is at least a certain length
    function ArrayClass:MinLength(MinLength)
        ExpectType(MinLength, "number", 1)

        return self:_AddConstraint("MinLength", function(_, TargetArray, MinLength)
            if (#TargetArray < MinLength) then
                return false, "Length must be at least " .. MinLength .. ", got " .. #TargetArray
            end

            return true, EMPTY_STRING
        end, MinLength)
    end
    ArrayClass.minLength = ArrayClass.MinLength

    --- Ensures an array is at most a certain length
    function ArrayClass:MaxLength(MaxLength)
        ExpectType(MaxLength, "number", 1)

        return self:_AddConstraint("MaxLength", function(_, TargetArray, MaxLength)
            if (#TargetArray > MaxLength) then
                return false, "Length must be at most " .. MaxLength .. ", got " .. #TargetArray
            end

            return true, EMPTY_STRING
        end, MaxLength)
    end
    ArrayClass.maxLength = ArrayClass.MaxLength

    --- Ensures an array contains some given value
    function ArrayClass:Contains(Value, StartPoint)
        if (Value == nil) then
            ExpectType(Value, "something", 1)
        end

        if (StartPoint) then
            ExpectType(StartPoint, "number", 2)
        end

        return self:_AddConstraint("Contains", function(_, TargetArray, Value, StartPoint)
            if (table.find(TargetArray, Value, StartPoint) == nil) then
                return false, "Value not found in array: " .. tostring(Value)
            end

            return true, EMPTY_STRING
        end, Value, StartPoint)
    end
    ArrayClass.contains = ArrayClass.Contains

    --- Ensures each value in the template array satisfies the passed type checker
    function ArrayClass:OfType(SubType)
        TypeGuard._AssertIsTypeBase(SubType, 1)

        return self:_AddConstraint("OfType", function(SelfRef, TargetArray, SubType)
            for Index, Value in ipairs(TargetArray) do
                local Success, SubMessage = SubType:Check(Value)

                if (not Success) then
                    return false, ERR_PREFIX:format((SelfRef._Tags.DenoteParams and PREFIX_PARAM or PREFIX_ARRAY), tostring(Index)) .. SubMessage
                end
            end

            return true, EMPTY_STRING
        end, SubType)
    end
    ArrayClass.ofType = ArrayClass.OfType

    -- Takes an array of types and checks it against the passed array
    function ArrayClass:OfStructure(SubTypesAtPositions)
        ExpectType(SubTypesAtPositions, "table", 1)

        -- Just in case the user does any weird mutation
        local SubTypesCopy = {}

        for Index, Value in ipairs(SubTypesAtPositions) do
            TypeGuard._AssertIsTypeBase(Value, Index)
            SubTypesCopy[Index] = Value
        end

        setmetatable(SubTypesCopy, STRUCTURE_TO_FLAT_STRING_MT)

        return self:_AddConstraint("OfStructure", function(SelfRef, TargetArray, SubTypesAtPositions)
            -- Check all fields which should be in the object exist (unless optional) and the type check for each passes
            for Index, Checker in ipairs(SubTypesAtPositions) do
                local Success, SubMessage = Checker:Check(TargetArray[Index])

                if (not Success) then
                    return false, SelfRef:_PrefixError(ERR_PREFIX, tostring(Index)) .. SubMessage
                end
            end

            -- Check there are no extra indexes which shouldn't be in the object
            if (SelfRef._Tags.Strict) then
                for Index in ipairs(TargetArray) do
                    local Checker = SubTypesAtPositions[Index]

                    if (not Checker) then
                        return false, SelfRef:_PrefixError(ERR_UNEXPECTED_VALUE, tostring(Index))
                    end
                end
            end

            return true, EMPTY_STRING
        end, SubTypesCopy, SubTypesAtPositions)
    end
    ArrayClass.ofStructure = ArrayClass.OfStructure

    --- OfStructure but strict
    function ArrayClass:StructuralEquals(Other)
        return self:OfStructure(Other):Strict()
    end
    ArrayClass.structuralEquals = ArrayClass.StructuralEquals

    --- Tags this ArrayTypeChecker as strict i.e. no extra indexes allowed in OfStructure constraint
    function ArrayClass:Strict()
        return self:AddTag("Strict")
    end
    ArrayClass.strict = ArrayClass.Strict

    --- Tags this ArrayTypeChecker as a params call (just for better information when using TypeGuard.Params)
    function ArrayClass:DenoteParams()
        return self:AddTag("DenoteParams")
    end
    ArrayClass.denoteParams = ArrayClass.DenoteParams

    ArrayClass._InitialConstraint = ArrayClass.OfType

    TypeGuard.Array = Array
end




do
    type ObjectTypeChecker = TypeChecker<ObjectTypeChecker> & {
        OfStructure: SelfReturn<ObjectTypeChecker, {[any]: TypeChecker<any>}>;
        ofStructure: SelfReturn<ObjectTypeChecker, {[any]: TypeChecker<any>}>;

        StructuralEquals: SelfReturn<ObjectTypeChecker, {[any]: TypeChecker<any>}>;
        structuralEquals: SelfReturn<ObjectTypeChecker, {[any]: TypeChecker<any>}>;

        Strict: SelfReturn<ObjectTypeChecker>;
        strict: SelfReturn<ObjectTypeChecker>;

        OfValueType: SelfReturn<ObjectTypeChecker, TypeChecker<any>>;
        ofValueType: SelfReturn<ObjectTypeChecker, TypeChecker<any>>;

        OfKeyType: SelfReturn<ObjectTypeChecker, TypeChecker<any>>;
        ofKeyType: SelfReturn<ObjectTypeChecker, TypeChecker<any>>;
    };

    local Object: TypeCheckerConstructor<ObjectTypeChecker, {[any]: TypeChecker<any>}>, ObjectClass = TypeGuard.Template("Object")

    function ObjectClass:_Initial(TargetObject)
        if (typeof(TargetObject) ~= "table") then
            return false, "Expected table, got " .. typeof(TargetObject)
        end

        for Key in pairs(TargetObject) do
            if (typeof(Key) == "number") then
                return false, "Incorrect key type: number"
            end
        end

        return true, EMPTY_STRING
    end

    --- Ensures every key that exists in the subject also exists in the structure passed, optionally strict i.e. no extra key-value pairs
    function ObjectClass:OfStructure(OriginalSubTypes)
        -- Just in case the user does any weird mutation
        local SubTypesCopy = {}

        for Index, Value in pairs(OriginalSubTypes) do
            TypeGuard._AssertIsTypeBase(Value, Index)
            SubTypesCopy[Index] = Value
        end

        setmetatable(SubTypesCopy, STRUCTURE_TO_FLAT_STRING_MT)

        return self:_AddConstraint("OfStructure", function(SelfRef, StructureCopy, SubTypes)
            -- Check all fields which should be in the object exist (unless optional) and the type check for each passes
            for Key, Checker in pairs(SubTypes) do
                local RespectiveValue = StructureCopy[Key]

                if (RespectiveValue == nil and not Checker._Tags.Optional) then
                    return false, "[Key '" .. tostring(Key) .. "'] is nil"
                end

                local Success, SubMessage = Checker:Check(RespectiveValue)

                if (not Success) then
                    return false, "[Key '" .. tostring(Key) .. "'] " .. SubMessage
                end
            end

            -- Check there are no extra fields which shouldn't be in the object
            if (SelfRef._Tags.Strict) then
                for Key in pairs(StructureCopy) do
                    local Checker = SubTypes[Key]

                    if (not Checker) then
                        return false, "[Key '" .. tostring(Key) .. "'] unexpected (strict)"
                    end
                end
            end

            return true, EMPTY_STRING
        end, SubTypesCopy)
    end
    ObjectClass.ofStructure = ObjectClass.OfStructure

    --- For all values in the passed table, they must satisfy the TypeChecker passed to this constraint
    function ObjectClass:OfValueType(SubType)
        TypeGuard._AssertIsTypeBase(SubType, 1)

        return self:_AddConstraint("OfValueType", function(_, TargetArray, SubType)
            for Index, Value in pairs(TargetArray) do
                local Success, SubMessage = SubType:Check(Value)

                if (not Success) then
                    return false, "[OfValueType: Key '" .. tostring(Index) .. "'] " .. SubMessage
                end
            end

            return true, EMPTY_STRING
        end, SubType)
    end
    ObjectClass.ofValueType = ObjectClass.OfValueType

    --- For all keys in the passed table, they must satisfy the TypeChecker passed to this constraint
    function ObjectClass:OfKeyType(SubType)
        TypeGuard._AssertIsTypeBase(SubType, 1)

        return self:_AddConstraint("OfKeyType", function(_, TargetArray, SubType)
            for Key in pairs(TargetArray) do
                local Success, SubMessage = SubType:Check(Key)

                if (not Success) then
                    return false, "[OfKeyType: Key '" .. tostring(Key) .. "'] " .. SubMessage
                end
            end

            return true, EMPTY_STRING
        end, SubType)
    end
    ObjectClass.ofKeyType = ObjectClass.OfKeyType

    --- Strict i.e. no extra key-value pairs than what is explicitly specified when using OfStructure
    function ObjectClass:Strict()
        return self:AddTag("Strict")
    end
    ObjectClass.strict = ObjectClass.Strict

    --- OfStructure but strict
    function ObjectClass:StructuralEquals(Structure)
        return self:OfStructure(Structure):Strict()
    end
    ObjectClass.structuralEquals = ObjectClass.StructuralEquals

    ObjectClass._InitialConstraint = ObjectClass.OfStructure

    TypeGuard.Object = Object
end




do
    type InstanceTypeChecker = TypeChecker<InstanceTypeChecker> & {
        OfStructure: SelfReturn<InstanceTypeChecker, {[any]: TypeChecker<Instance>}>;
        ofStructure: SelfReturn<InstanceTypeChecker, {[any]: TypeChecker<Instance>}>;

        StructuralEquals: SelfReturn<InstanceTypeChecker, {[any]: TypeChecker<Instance>}>;
        structuralEquals: SelfReturn<InstanceTypeChecker, {[any]: TypeChecker<Instance>}>;

        IsA: SelfReturn<InstanceTypeChecker, string>;
        isA: SelfReturn<InstanceTypeChecker, string>;

        Strict: SelfReturn<InstanceTypeChecker>;
        strict: SelfReturn<InstanceTypeChecker>;
    };

    local function Get(Inst, Key)
        return Inst[Key]
    end

    local function TryGet(Inst, Key)
        local Success, Result = pcall(Get, Inst, Key)

        if (Success) then
            return Result
        end

        return nil
    end

    local InstanceChecker: TypeCheckerConstructor<InstanceTypeChecker, string?, {[string]: TypeChecker<any>}?>, InstanceCheckerClass = TypeGuard.Template("Instance")
    InstanceCheckerClass._Initial = CreateStandardInitial("Instance")

    --- Ensures that an Instance has specific children (this is not for properties)
    --- @todo Check properties too
    function InstanceCheckerClass:OfStructure(OriginalSubTypes)
        -- Just in case the user does any weird mutation
        local SubTypesCopy = {}

        for Key, Value in pairs(OriginalSubTypes) do
            TypeGuard._AssertIsTypeBase(Value, Key)
            SubTypesCopy[Key] = Value
        end

        setmetatable(SubTypesCopy, STRUCTURE_TO_FLAT_STRING_MT)

        return self:_AddConstraint("OfStructure", function(SelfRef, InstanceRoot, SubTypes)
            -- Check all properties and children which should be in the Instance exist (unless optional) and the type check for each passes
            for Key, Checker in pairs(SubTypes) do
                local Value = TryGet(InstanceRoot, Key)
                local Success, SubMessage = Checker:Check(Value)

                if (not Success) then
                    return false, (typeof(Value) == "Instance" and "[Instance '" or "[Property '") .. tostring(Key) .. "'] " .. SubMessage
                end
            end

            -- Check there are no extra children which shouldn't be in the Instance
            if (SelfRef._Tags.Strict) then
                for _, Value in ipairs(InstanceRoot:GetChildren()) do
                    local Key = Value.Name
                    local Checker = SubTypes[Key]

                    if (not Checker) then
                        return false, "[Instance '" .. tostring(Key) .. "'] unexpected (strict)"
                    end
                end
            end

            return true, EMPTY_STRING
        end, SubTypesCopy)
    end
    InstanceCheckerClass.ofStructure = InstanceCheckerClass.OfStructure

    --- Uses Instance.IsA to assert the type of an Instance
    function InstanceCheckerClass:IsA(InstanceIsA)
        ExpectType(InstanceIsA, "string", 1)

        return self:_AddConstraint("IsA", function(_, InstanceRoot, InstanceIsA)
            if (not InstanceRoot:IsA(InstanceIsA)) then
                return false, "Expected " .. InstanceIsA .. ", got " .. InstanceRoot.ClassName
            end

            return true, EMPTY_STRING
        end, InstanceIsA)
    end
    InstanceCheckerClass.isA = InstanceCheckerClass.IsA

    --- Activates strict tag for OfStructure
    function InstanceCheckerClass:Strict()
        return self:AddTag("Strict")
    end
    InstanceCheckerClass.strict = InstanceCheckerClass.Strict

    --- OfStructure + strict tag i.e. no extra children exist beyond what is specified
    function InstanceCheckerClass:StructuralEquals(Structure)
        return self:OfStructure(Structure):Strict()
    end
    InstanceCheckerClass.structuralEquals = InstanceCheckerClass.StructuralEquals

    InstanceCheckerClass._InitialConstraints = {InstanceCheckerClass.IsA, InstanceCheckerClass.OfStructure}

    TypeGuard.Instance = InstanceChecker
end




do
    type BooleanTypeChecker = TypeChecker<BooleanTypeChecker> & {};

    local Boolean: TypeCheckerConstructor<BooleanTypeChecker>, BooleanClass = TypeGuard.Template("Boolean")
    BooleanClass._Initial = CreateStandardInitial("boolean")

    BooleanClass._InitialConstraint = BooleanClass.Equals

    TypeGuard.Boolean = Boolean
    TypeGuard.boolean = Boolean
end




do
    type EnumTypeChecker = TypeChecker<EnumTypeChecker> & {
        IsA: SelfReturn<EnumTypeChecker, Enum | EnumItem>;
        isA: SelfReturn<EnumTypeChecker, Enum | EnumItem>;
    };

    local EnumChecker: TypeCheckerConstructor<EnumTypeChecker>, EnumCheckerClass = TypeGuard.Template("Enum")

    function EnumCheckerClass:_Initial(Value)
        local GotType = typeof(Value)

        if (GotType ~= "EnumItem" and GotType ~= "Enum") then
            return false, "Expected EnumItem or Enum, got " .. GotType
        end

        return true, EMPTY_STRING
    end

    --- Ensures that a passed EnumItem is either equivalent to an EnumItem or a sub-item of an Enum class
    function EnumCheckerClass:IsA(TargetEnum)
        local GotType = typeof(TargetEnum)
        assert(GotType == "Enum" or GotType == "EnumItem", INVALID_ARGUMENT:format("1", "Enum or EnumItem", GotType))

        return self:_AddConstraint("IsA", function(_, Value, TargetEnum)
            local PassedType = typeof(Value)
            local TargetType = typeof(TargetEnum)

            if (PassedType ~= "EnumItem" and PassedType ~= "Enum") then
                return false, "Expected EnumItem, got " .. PassedType
            end

            -- Both are EnumItems
            if (TargetType == "EnumItem") then
                if (Value == TargetEnum) then
                    return true, EMPTY_STRING
                end

                return false, "Expected " .. tostring(TargetEnum) .. ", got " .. tostring(Value)
            end

            -- TargetType is an Enum
            if (table.find(TargetEnum:GetEnumItems(), Value) == nil) then
                return false, "Expected a " .. tostring(TargetEnum) .. ", got " .. tostring(Value)
            end

            return true, EMPTY_STRING
        end, TargetEnum)
    end
    EnumCheckerClass.isA = EnumCheckerClass.IsA

    EnumCheckerClass._InitialConstraint = EnumCheckerClass.IsA

    TypeGuard.Enum = EnumChecker
end




do
    type NilTypeChecker = TypeChecker<NilTypeChecker> & {};

    local NilChecker: TypeCheckerConstructor<NilTypeChecker>, NilCheckerClass = TypeGuard.Template("Nil")

    function NilCheckerClass:_Initial(Value)
        if (Value == nil) then
            return true, EMPTY_STRING
        end

        return false, "Expected nil, got " .. typeof(Value)
    end

    TypeGuard.Nil = NilChecker
    TypeGuard["nil"] = NilChecker
end




do
    type ThreadTypeChecker = TypeChecker<ThreadTypeChecker> & {};

    local ThreadChecker: TypeCheckerConstructor<ThreadTypeChecker>, ThreadCheckerClass = TypeGuard.Template("Thread")
    ThreadCheckerClass._Initial = CreateStandardInitial("thread")

    function ThreadCheckerClass:IsDead()
        return self:HasStatus("dead"):AddTag("StatusCheck")
    end

    function ThreadCheckerClass:IsSuspended()
        return self:HasStatus("suspended"):AddTag("StatusCheck")
    end

    function ThreadCheckerClass:IsRunning()
        return self:HasStatus("running"):AddTag("StatusCheck")
    end

    function ThreadCheckerClass:IsNormal()
        return self:HasStatus("normal"):AddTag("StatusCheck")
    end

    --- Checks the coroutine's status against a given status string
    function ThreadCheckerClass:HasStatus(Status: string)
        ExpectType(Status, "string", 1)

        return self:_AddConstraint("HasStatus", function(_, Thread, Status)
            local CurrentStatus = coroutine.status(Thread)

            if (CurrentStatus == Status) then
                return true, EMPTY_STRING
            end

            return false, "Expected thread to have status '" .. Status .. "', got " .. CurrentStatus
        end, Status)
    end

    TypeGuard._InitialConstraint = ThreadCheckerClass.HasStatus

    TypeGuard.Thread = ThreadChecker
    TypeGuard.thread = ThreadChecker
end




TypeGuard.Axes = TypeGuard.FromTypeName("Axes")
TypeGuard.BrickColor = TypeGuard.FromTypeName("BrickColor")
TypeGuard.CatalogSearchParams = TypeGuard.FromTypeName("CatalogSearchParams")
TypeGuard.CFrame = TypeGuard.FromTypeName("CFrame")
TypeGuard.Color3 = TypeGuard.FromTypeName("Color3")
TypeGuard.ColorSequence = TypeGuard.FromTypeName("ColorSequence")
TypeGuard.ColorSequenceKeypoint = TypeGuard.FromTypeName("ColorSequenceKeypoint")
TypeGuard.DateTime = TypeGuard.FromTypeName("DateTime")
TypeGuard.DockWidgetPluginGuiInfo = TypeGuard.FromTypeName("DockWidgetPluginGuiInfo")
TypeGuard.Enums = TypeGuard.FromTypeName("Enums")
TypeGuard.Faces = TypeGuard.FromTypeName("Faces")
TypeGuard.FloatCurveKey = TypeGuard.FromTypeName("FloatCurveKey")
TypeGuard.NumberRange = TypeGuard.FromTypeName("NumberRange")
TypeGuard.NumberSequence = TypeGuard.FromTypeName("NumberSequence")
TypeGuard.NumberSequenceKeypoint = TypeGuard.FromTypeName("NumberSequenceKeypoint")
TypeGuard.OverlapParams = TypeGuard.FromTypeName("OverlapParams")
TypeGuard.PathWaypoint = TypeGuard.FromTypeName("PathWaypoint")
TypeGuard.PhysicalProperties = TypeGuard.FromTypeName("PhysicalProperties")
TypeGuard.Random = TypeGuard.FromTypeName("Random")
TypeGuard.Ray = TypeGuard.FromTypeName("Ray")
TypeGuard.RaycastParams = TypeGuard.FromTypeName("RaycastParams")
TypeGuard.RaycastResult = TypeGuard.FromTypeName("RaycastResult")
TypeGuard.RBXScriptConnection = TypeGuard.FromTypeName("RBXScriptConnection")
TypeGuard.RBXScriptSignal = TypeGuard.FromTypeName("RBXScriptSignal")
TypeGuard.Rect = TypeGuard.FromTypeName("Rect")
TypeGuard.Region3 = TypeGuard.FromTypeName("Region3")
TypeGuard.Region3int16 = TypeGuard.FromTypeName("Region3int16")
TypeGuard.TweenInfo = TypeGuard.FromTypeName("TweenInfo")
TypeGuard.UDim = TypeGuard.FromTypeName("UDim")
TypeGuard.UDim2 = TypeGuard.FromTypeName("UDim2")
TypeGuard.Vector2 = TypeGuard.FromTypeName("Vector2")
TypeGuard.Vector2int16 = TypeGuard.FromTypeName("Vector2int16")
TypeGuard.Vector3 = TypeGuard.FromTypeName("Vector3")
TypeGuard.Vector3int16 = TypeGuard.FromTypeName("Vector3int16")

--- Creates a function which checks params as if they were a strict Array checker
function TypeGuard.Params(...: TypeChecker<any>)
    local Params = {...}

    for Index, ParamChecker in ipairs(Params) do
        TypeGuard._AssertIsTypeBase(ParamChecker, Index)
    end

    local Checker = TypeGuard.Array():StructuralEquals(Params):DenoteParams()

    return function(...)
        Checker:Assert({...})
    end
end
TypeGuard.params = TypeGuard.Params

--- Creates a function which checks variadic params against a single given type checker
function TypeGuard.VariadicParams(CompareType: TypeChecker<any>)
    TypeGuard._AssertIsTypeBase(CompareType, 1)

    local Checker = TypeGuard.Array():OfType(CompareType):DenoteParams()

    return function(...)
        Checker:Assert({...})
    end
end
TypeGuard.variadicParams = TypeGuard.VariadicParams

-- Wraps a function in a param checker function
function TypeGuard.WrapFunctionParams<T>(Call: T, ...: TypeChecker<any>)
    ExpectType(Call, "function", 1)

    for Index = 1, select("#", ...) do
        TypeGuard._AssertIsTypeBase(select(Index, ...), Index)
    end

    local ParamChecker = TypeGuard.Params(...)

    return function(...)
        ParamChecker(...)
        return Call(...)
    end
end

-- Wraps a function in a variadic param checker function
function TypeGuard.WrapFunctionVariadicParams<T>(Call: T, VariadicParamType: TypeChecker<any>)
    ExpectType(Call, "function", 1)
    TypeGuard._AssertIsTypeBase(VariadicParamType, 2)

    local ParamChecker = TypeGuard.VariadicParams(VariadicParamType)

    return function(...)
        ParamChecker(...)
        return Call(...)
    end
end

return TypeGuard