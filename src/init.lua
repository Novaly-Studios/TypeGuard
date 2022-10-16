local CollectionService = game:GetService("CollectionService")
-- @TODO This script really needs splitting up into sub-modules

local CHECK_TAG_SUFFIX = ".Check"
local EMPTY_STRING = ""

local TYPE_SOMETHING = "something"
local TYPE_ENUM_ITEM = "EnumItem"
local TYPE_INSTANCE = "Instance"
local TYPE_ENUM = "Enum"

local TYPE_FUNCTION = "function"
local TYPE_USERDATA = "userdata"
local TYPE_BOOLEAN = "boolean"
local TYPE_THREAD = "thread"
local TYPE_NUMBER = "number"
local TYPE_STRING = "string"
local TYPE_TABLE = "table"
local TYPE_NIL = "nil"

local INVALID_ARGUMENT = "Invalid argument #%s (%s expected, got %s)"
local INVALID_TYPE = "Expected %s, got %s"

-- Cache up here so these arrays aren't re-created with every function call for the simple checking system
local EXPECT_ENUM_OR_ENUM_ITEM_OR_FUNCTION = {TYPE_ENUM, TYPE_ENUM_ITEM, TYPE_FUNCTION}
local EXPECT_INSTANCE_OR_FUNCTION = {TYPE_INSTANCE, TYPE_FUNCTION}
local EXPECT_BOOLEAN_OR_FUNCTION = {TYPE_BOOLEAN, TYPE_FUNCTION}
local EXPECT_STRING_OR_FUNCTION = {TYPE_STRING, TYPE_FUNCTION}
local EXPECT_NUMBER_OR_FUNCTION = {TYPE_NUMBER, TYPE_FUNCTION}
local EXPECT_TABLE_OR_FUNCTION = {TYPE_TABLE, TYPE_FUNCTION}
local EXPECT_SOMETHING = {TYPE_SOMETHING}
local EXPECT_FUNCTION = {TYPE_FUNCTION}
local EXPECT_BOOLEAN = {TYPE_BOOLEAN}
local EXPECT_STRING = {TYPE_STRING}
local EXPECT_TABLE = {TYPE_TABLE}

--- This is only really for type checking internally for data passed to constraints and util functions
local function ExpectType<T>(PassedArg: T, ExpectedTypes: {string}, ArgKey: number | string)
    local GotType = typeof(PassedArg)
    local Satisfied = false

    for _, PossibleType in ExpectedTypes do
        if (GotType == PossibleType) then
            Satisfied = true
            break
        end
    end

    assert(Satisfied, INVALID_ARGUMENT:format(tostring(ArgKey), table.concat(ExpectedTypes, " or "), GotType))
end

local function CreateStandardInitial(ExpectedTypeName: string): ((...any) -> (boolean, string))
    return function(_, Item)
        local ItemType = typeof(Item)

        if (ItemType == ExpectedTypeName) then
            return true, EMPTY_STRING
        end

        return false, INVALID_TYPE:format(ExpectedTypeName, ItemType)
    end
end

local function ConcatWithToString<T>(Array: {T}, Separator: string): string
    local Result = EMPTY_STRING

    for _, Value in Array do
        Result ..= tostring(Value) .. Separator
    end

    return (#Array > 0 and Result:sub(1, #Result - #Separator) or Result)
end

local STRUCTURE_TO_FLAT_STRING_MT = {
    __tostring = function(self)
        local Pairings = {}

        for Key, Value in self do
            table.insert(Pairings, tostring(Key) .. " = " .. tostring(Value))
        end

        return "{" .. ConcatWithToString(Pairings, ", ") .. "}"
    end;
}

local WEAK_KEY_MT = {__mode = "k"}

-- Standard re-usable functions throughout all TypeCheckers
    local function IsAKeyIn(self, Store)
        ExpectType(Store, EXPECT_TABLE_OR_FUNCTION, 1)

        return self:_AddConstraint(false, "IsAKeyIn", function(_, Key, Store)
            if (Store[Key] == nil) then
                return false, "Key " .. tostring(Key) .. " was not found in table: " .. tostring(Store)
            end

            return true, EMPTY_STRING
        end, Store)
    end

    local function IsAValueIn(self, Store)
        ExpectType(Store, EXPECT_TABLE_OR_FUNCTION, 1)

        return self:_AddConstraint(false, "IsAValueIn", function(_, TargetValue, Store)
            for _, Value in Store do
                if (Value == TargetValue) then
                    return true, EMPTY_STRING
                end
            end

            return false, "Value " .. tostring(TargetValue) .. " was not found in table: " .. tostring(Store)
        end, Store)
    end

    local function Equals(self, ExpectedValue)
        return self:_AddConstraint(true, "Equals", function(_, Value, ExpectedValue)
            if (Value == ExpectedValue) then
                return true, EMPTY_STRING
            end

            return false, "Value " .. tostring(Value) .. " does not equal " .. tostring(ExpectedValue)
        end, ExpectedValue)
    end

    local function GreaterThan(self, GTValue)
        return self:_AddConstraint(true, "GreaterThan", function(_, Value, GTValue)
            if (Value > GTValue) then
                return true, EMPTY_STRING
            end

            return false, "Value " .. tostring(Value) .. " is not greater than " .. tostring(GTValue)
        end, GTValue)
    end

    local function LessThan(self, LTValue)
        return self:_AddConstraint(true, "LessThan", function(_, Value, LTValue)
            if (Value < LTValue) then
                return true, EMPTY_STRING
            end

            return false, "Value " .. tostring(Value) .. " is not less than " .. tostring(LTValue)
        end, LTValue)
    end

    local function GreaterThanOrEqualTo(self, GTEValue)
        return self:_AddConstraint(true, "GreaterThanOrEqualTo", function(_, Value, GTEValue)
            if (Value >= GTEValue) then
                return true, EMPTY_STRING
            end

            return false, "Value " .. tostring(Value) .. " is not greater than or equal to " .. tostring(GTEValue)
        end, GTEValue)
    end

    local function LessThanOrEqualTo(self, LTEValue)
        return self:_AddConstraint(true, "LessThanOrEqualTo", function(_, Value, LTEValue)
            if (Value <= LTEValue) then
                return true, EMPTY_STRING
            end

            return false, "Value " .. tostring(Value) .. " is not less than or equal to " .. tostring(LTEValue)
        end, LTEValue)
    end




type SelfReturn<T, P...> = ((T, P...) -> T)

type TypeCheckerConstructor<T, P...> = ((P...) -> T)

type TypeChecker<T> = {
    Or: SelfReturn<T, TypeChecker<any> | () -> TypeChecker<any>>;
    And: SelfReturn<T, TypeChecker<any>>;
    Alias: SelfReturn<T, string>;
    Negate: SelfReturn<T>;
    Cached: SelfReturn<T>;
    Optional: SelfReturn<T>;
    WithContext: SelfReturn<T, any?>;
    FailMessage: SelfReturn<T, string>;

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

    GreaterThan: SelfReturn<T, number | (any?) -> number>;
    greaterThan: SelfReturn<T, number | (any?) -> number>;

    LessThan: SelfReturn<T, number | (any?) -> number>;
    lessThan: SelfReturn<T, number | (any?) -> number>;

    GreaterThanOrEqualTo: SelfReturn<T, number | (any?) -> number>;
    greaterThanOrEqualTo: SelfReturn<T, number | (any?) -> number>;

    LessThanOrEqualTo: SelfReturn<T, number | (any?) -> number>;
    lessThanOrEqualTo: SelfReturn<T, number | (any?) -> number>;
};

local RootContext -- Faster & easier just using one high scope variable which all TypeCheckers can access during checking time, than propogating the context downwards
local TypeGuard = {}

--- Creates a template TypeChecker object that can be used to extend behaviors via constraints
function TypeGuard.Template(Name: string)
    ExpectType(Name, EXPECT_STRING, 1)

    local TemplateClass = {}
    TemplateClass.__index = TemplateClass
    TemplateClass._InitialConstraints = nil
    TemplateClass._InitialConstraint = nil
    TemplateClass.IsTemplate = true
    TemplateClass.Type = Name

    function TemplateClass.new(...)
        local self = {
            _Tags = {};
            _Disjunction = {};
            _Conjunction = {};
            _ActiveConstraints = {};

            _LastConstraint = EMPTY_STRING;

            _Cache = nil;
            _Context = nil;
            _FailMessage = nil;
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

    function TemplateClass:Copy()
        local New = TemplateClass.new()

        -- Copy tags
        for Key, Value in self._Tags do
            New._Tags[Key] = Value
        end

        -- Copy OR
        for Index, Disjunction in self._Disjunction do
            New._Disjunction[Index] = Disjunction
        end

        -- Copy AND
        for Index, Conjunction in self._Conjunction do
            New._Conjunction[Index] = Conjunction
        end

        -- Copy constraints
        for ConstraintName, Constraint in self._ActiveConstraints do
            New._ActiveConstraints[ConstraintName] = Constraint
        end

        New._Context = self._Context
        New._FailMessage = self._FailMessage
        New._LastConstraint = self._LastConstraint

        return New
    end
    TemplateClass.copy = TemplateClass.Copy

    --- Wraps & negates the last constraint (i.e. if it originally would fail, it passes, and vice versa)
    function TemplateClass:Negate()
        self = self:Copy()

        local LastConstraint = self._LastConstraint
        assert(LastConstraint ~= EMPTY_STRING, "Nothing to negate! (No constraints active)")
        self._ActiveConstraints[LastConstraint][4] = true

        return self
    end
    TemplateClass.negate = TemplateClass.Negate

    --- Sets a custom fail message to return if Check() fails
    function TemplateClass:FailMessage(Message: string)
        ExpectType(Message, EXPECT_STRING, 1)

        self = self:Copy()
        self._FailMessage = Message
        return self
    end
    TemplateClass.failMessage = TemplateClass.FailMessage

    function TemplateClass:Cached()
        return self:_AddTag("Cached")
    end
    TemplateClass.cached = TemplateClass.Cached

    function TemplateClass:_AddConstraint(OnlyOnce, ConstraintName, Constraint, ...)
        if (OnlyOnce ~= nil) then
            ExpectType(OnlyOnce, EXPECT_BOOLEAN, 1)
        end

        ExpectType(ConstraintName, EXPECT_STRING, 2)
        ExpectType(Constraint, EXPECT_FUNCTION, 3)

        self = self:Copy()

        local Args = {...}
        local HasFunctions = false

        for _, Value in Args do
            local ArgType = typeof(Value)

            if (ArgType == TYPE_FUNCTION) then
                HasFunctions = true
                continue
            end
        end

        local ActiveConstraints = self._ActiveConstraints
        --assert(ActiveConstraints[ConstraintName] == nil, "Constraint already exists: " .. ConstraintName)

        if (OnlyOnce) then
            local Found = false

            for _, ConstraintData in ActiveConstraints do
                if (ConstraintData[5] == ConstraintName) then
                    Found = true
                    break
                end
            end

            if (Found) then
                error("Attempt to apply a constraint marked as 'only once' more than once: " .. ConstraintName)
            end
        end

        --ActiveConstraints[ConstraintName] = {Constraint, Args, HasFunctions, false}
        local NextIndex = #ActiveConstraints + 1
        ActiveConstraints[NextIndex] = {Constraint, Args, HasFunctions, false, ConstraintName}
        self._LastConstraint = NextIndex
        return self
    end

    --- Adds a tag (for internal purposes)
    function TemplateClass:_AddTag(TagName)
        ExpectType(TagName, EXPECT_STRING, 1)
        assert(self._Tags[TagName] == nil, "Tag already exists: " .. TagName)

        self = self:Copy()
        self._Tags[TagName] = true
        return self
    end

    function TemplateClass:_GetCache()
        local Cache = self._Cache

        if (not Cache) then
            Cache = setmetatable({}, WEAK_KEY_MT); -- Weak keys because we don't want to leak Instances or tables
            self._Cache = Cache
        end

        return Cache
    end

    --- Checks if the value is of the correct type
    function TemplateClass:_Check(Value)
        debug.profilebegin(Name .. CHECK_TAG_SUFFIX)

        local Tags = self._Tags
        local CacheTag = Tags.Cached
        local Cache

        if (CacheTag) then
            Cache = self:_GetCache()

            local CacheValue = Cache[Value]

            if (CacheValue) then
                local Success = CacheValue[1]
                local Result = CacheValue[2]
                debug.profileend()
                return Success, Result
            end
        end

        -- Handle "type x or type y or type z ..."
        -- We do this before checking constraints to check if any of the other conditions succeed
        local Disjunctions = self._Disjunction
        local DidTryDisjunction = (Disjunctions[1] ~= nil)

        for _, AlternateType in Disjunctions do
            if (typeof(AlternateType) == TYPE_FUNCTION) then
                AlternateType = AlternateType(self)
            end

            local Success, _ = AlternateType:_Check(Value)

            if (Success) then
                if (CacheTag) then
                    Cache[Value] = {true, EMPTY_STRING}
                end

                debug.profileend()
                return true, EMPTY_STRING
            end
        end

        -- Handle "type x and type y and type z ..." - this is only really useful for objects and arrays
        for _, Conjunction in self._Conjunction do
            local Success, Message = Conjunction:_Check(Value)

            if (not Success) then
                local Result = self._FailMessage or ("[Conjunction " .. tostring(Conjunction) .. "] " .. Message)

                if (CacheTag) then
                    Cache[Value] = {false, Result}
                end

                debug.profileend()
                return false, Result
            end
        end

        -- Optional allows the value to be nil, in which case it won't be checked and we can resolve
        if (Tags.Optional and Value == nil) then
            if (CacheTag) then
                Cache[Value] = {true, EMPTY_STRING}
            end

            debug.profileend()
            return true, EMPTY_STRING
        end

        -- Handle initial type check
        local Success, Message = self:_Initial(Value)

        if (not Success) then
            if (DidTryDisjunction) then
                local Result = self._FailMessage or ("Disjunctions failed on " .. tostring(self))

                if (CacheTag) then
                    Cache[Value] = {false, Result}
                end

                debug.profileend()
                return false, Result
            else
                Message = self._FailMessage or Message

                if (CacheTag) then
                    Cache[Value] = {false, Message}
                end

                debug.profileend()
                return false, Message
            end
        end

        -- Handle active constraints
        for _, Constraint in self._ActiveConstraints do
            local Call = Constraint[1]
            local Args = Constraint[2]
            local HasFunctionalParams = Constraint[3]
            local ShouldNegate = Constraint[4]
            local ConstraintName = Constraint[5]

            -- Functional params -> transform into values when type checking
            if (HasFunctionalParams) then
                Args = table.clone(Args)

                for Index, Arg in Args do
                    if (typeof(Arg) == TYPE_FUNCTION) then
                        Args[Index] = Arg(RootContext)
                    end
                end
            end

            -- Call the constraint to verify it is satisfied
            local SubSuccess, SubMessage = Call(self, Value, unpack(Args))

            if (ShouldNegate) then
                SubMessage = if (SubSuccess) then
                                "Constraint '" .. ConstraintName .. "' succeeded but was expected to fail on value " .. tostring(Value)
                                else
                                EMPTY_STRING

                SubSuccess = not SubSuccess
            end

            if (not SubSuccess) then
                if (DidTryDisjunction) then
                    local Result = self._FailMessage or ("Disjunctions failed on " .. tostring(self))

                    if (CacheTag) then
                        Cache[Value] = {false, Result}
                    end

                    debug.profileend()
                    return false, Result
                else
                    SubMessage = self._FailMessage or SubMessage

                    if (CacheTag) then
                        Cache[Value] = {false, SubMessage}
                    end

                    debug.profileend()
                    return false, SubMessage
                end
            end
        end

        if (CacheTag) then
            Cache[Value] = {true, EMPTY_STRING}
        end

        debug.profileend()
        return true, EMPTY_STRING
    end

    --- Calling this will only check the type of the passed value if that value is not nil, i.e. it's an optional value so nothing can be passed, but if it is not nothing then it will be checked
    function TemplateClass:Optional()
        return self:_AddTag("Optional")
    end
    TemplateClass.optional = TemplateClass.Optional

    --- Enqueues a new constraint to satisfy 'or' i.e. "check x or check y or check z or ..." must pass
    function TemplateClass:Or(OtherType)
        if (typeof(OtherType) ~= TYPE_FUNCTION) then
            TypeGuard._AssertIsTypeBase(OtherType, 1)
        end

        self = self:Copy()
        table.insert(self._Disjunction, OtherType)
        return self
    end
    TemplateClass["or"] = TemplateClass.Or

    --- Enqueues a new constraint to satisfy 'and' i.e. "check x and check y and check z and ..." must pass
    function TemplateClass:And(OtherType)
        TypeGuard._AssertIsTypeBase(OtherType, 1)

        self = self:Copy()
        table.insert(self._Conjunction, OtherType)
        return self
    end
    TemplateClass["and"] = TemplateClass.And

    --- Creates an Alias - useful for replacing large "Or" chains in big structures to identify where it is failing
    function TemplateClass:Alias(AliasName)
        ExpectType(AliasName, EXPECT_STRING, 1)

        self = self:Copy()
        self._Alias = AliasName
        return self
    end
    TemplateClass.alias = TemplateClass.Alias

    --- Passes down a "context" value to constraints with functional values
    --- We don't copy here because performance is important at the checking phase
    function TemplateClass:WithContext(Context)
        self._Context = Context
        return self
    end
    TemplateClass.withContext = TemplateClass.WithContext

    --- Wrap Check into its own callable function
    function TemplateClass:WrapCheck()
        return function(Value)
            return self:_Check(Value)
        end
    end
    TemplateClass.wrapCheck = TemplateClass.WrapCheck

    --- Wraps Assert into its own callable function
    function TemplateClass:WrapAssert()
        return function(Value)
            return self:Assert(Value)
        end
    end
    TemplateClass.wrapAssert = TemplateClass.WrapAssert

    --- Check (like above) except sets a universal context for the duration of the check
    function TemplateClass:Check(Value)
        RootContext = self._Context
        local Success, Result = self:_Check(Value)
        RootContext = nil
        return Success, Result
    end
    TemplateClass.check = TemplateClass.Check

    --- Throws an error if the check is unsatisfied
    function TemplateClass:Assert(Value)
        assert(self:Check(Value))
    end
    TemplateClass.assert = TemplateClass.Assert

    function TemplateClass:__tostring()
        -- User can create a unique alias to help simplify "where did it fail?"
        if (self._Alias) then
            return self._Alias
        end

        local Fields = {}

        -- Constraints list (including arg, possibly other type defs)
        if (next(self._ActiveConstraints) ~= nil) then
            local InnerConstraints = {}

            for _, Constraint in self._ActiveConstraints do
                table.insert(InnerConstraints, Constraint[5] .. "(" .. ConcatWithToString(Constraint[2], ", ") .. ")")
            end

            table.insert(Fields, "Constraints = {" .. ConcatWithToString(InnerConstraints, ", ") .. "}")
        end

        -- Alternatives field str
        if (#self._Disjunction > 0) then
            local Alternatives = {}

            for _, AlternateType in self._Disjunction do
                table.insert(Alternatives, tostring(AlternateType))
            end

            table.insert(Fields, "Or = {" .. ConcatWithToString(Alternatives, ", ") .. "}")
        end

        -- Union fields str
        if (#self._Conjunction > 0) then
            local Unions = {}

            for _, Union in self._Conjunction do
                table.insert(Unions, tostring(Union))
            end

            table.insert(Fields, "And = {" .. ConcatWithToString(Unions, ", ") .. "}")
        end

        -- Tags (e.g. Optional, Strict)
        if (next(self._Tags) ~= nil) then
            local Tags = {}

            for Tag in self._Tags do
                table.insert(Tags, Tag)
            end

            table.insert(Fields, "Tags = {" .. ConcatWithToString(Tags, ", ") .. "}")
        end

        if (self._Context) then
            table.insert(Fields, "Context = " .. tostring(self._Context))
        end

        return self.Type .. "(" .. ConcatWithToString(Fields, ", ") .. ")"
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
function TypeGuard._AssertIsTypeBase(Subject: any, Position: number | string)
    ExpectType(Subject, EXPECT_TABLE, Position)

    assert(Subject.IsTemplate, "Subject is not a type template")
end

--- Cheap & easy way to create a type without any constraints, and just an initial check corresponding to Roblox's typeof
function TypeGuard.FromTypeName(TypeName: string)
    ExpectType(TypeName, EXPECT_STRING, 1)

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

        RangeInclusive: SelfReturn<NumberTypeChecker, number | (any?) -> number, number | (any?) -> number>;
        rangeInclusive: SelfReturn<NumberTypeChecker, number | (any?) -> number, number | (any?) -> number>;

        RangeExclusive: SelfReturn<NumberTypeChecker, number | (any?) -> number, number | (any?) -> number>;
        rangeExclusive: SelfReturn<NumberTypeChecker, number | (any?) -> number, number | (any?) -> number>;

        Positive: SelfReturn<NumberTypeChecker>;
        positive: SelfReturn<NumberTypeChecker>;

        Negative: SelfReturn<NumberTypeChecker>;
        negative: SelfReturn<NumberTypeChecker>;

        IsNaN: SelfReturn<NumberTypeChecker>;
        isNan: SelfReturn<NumberTypeChecker>;

        IsInfinite: SelfReturn<NumberTypeChecker>;
        isInfinite: SelfReturn<NumberTypeChecker>;

        IsClose: SelfReturn<NumberTypeChecker, number | (any?) -> number, number | (any?) -> number>;
        isClose: SelfReturn<NumberTypeChecker, number | (any?) -> number, number | (any?) -> number>;
    };

    local Number: TypeCheckerConstructor<NumberTypeChecker, TypeChecker<any>?>, NumberClass = TypeGuard.Template("Number")
    NumberClass._Initial = CreateStandardInitial(TYPE_NUMBER)

    --- Checks if the value is whole
    function NumberClass:Integer()
        return self:_AddConstraint(true, "Integer", function(_, Item)
            if (Item % 1 == 0) then
                return true, EMPTY_STRING
            end

            return false, "Expected integer form, got " .. tostring(Item)
        end)
    end
    NumberClass.integer = NumberClass.Integer

    --- Checks if the number is a decimal
    function NumberClass:Decimal()
        return self:_AddConstraint(true, "Decimal", function(_, Item)
            if (Item % 1 ~= 0) then
                return true, EMPTY_STRING
            end

            return false, "Expected decimal form, got " .. tostring(Item)
        end)
    end
    NumberClass.decimal = NumberClass.Decimal

    --- Ensures a number is between or equal to a minimum and maxmimu value
    function NumberClass:RangeInclusive(Min, Max)
        ExpectType(Min, EXPECT_NUMBER_OR_FUNCTION, 1)
        ExpectType(Max, EXPECT_NUMBER_OR_FUNCTION, 2)

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
        return self:_AddConstraint(true, "Positive", function(_, Item)
            if (Item < 0) then
                return false, "Expected positive number, got " .. tostring(Item)
            end

            return true, EMPTY_STRING
        end)
    end
    NumberClass.positive = NumberClass.Positive

    --- Checks the number is negative
    function NumberClass:Negative()
        return self:_AddConstraint(true, "Negative", function(_, Item)
            if (Item >= 0) then
                return false, "Expected negative number, got " .. tostring(Item)
            end

            return true, EMPTY_STRING
        end)
    end
    NumberClass.negative = NumberClass.Negative

    --- Checks if the number is NaN
    function NumberClass:IsNaN()
        return self:_AddConstraint(true, "IsNaN", function(_, Item)
            if (Item ~= Item) then
                return true, EMPTY_STRING
            end

            return false, "Expected NaN, got " .. tostring(Item)
        end)
    end
    NumberClass.isNaN = NumberClass.IsNaN

    --- Checks if the number is infinite
    function NumberClass:IsInfinite()
        return self:_AddConstraint(true, "IsInfinite", function(_, Item)
            if (Item == math.huge or Item == -math.huge) then
                return true, EMPTY_STRING
            end

            return false, "Expected infinite, got " .. tostring(Item)
        end)
    end
    NumberClass.isInfinite = NumberClass.IsInfinite

    --- Checks if the number is close to another
    function NumberClass:IsClose(CloseTo, Tolerance)
        ExpectType(CloseTo, EXPECT_NUMBER_OR_FUNCTION, 1)
        Tolerance = Tolerance or 0.00001

        return self:_AddConstraint(true, "IsClose", function(_, NumberValue, CloseTo, Tolerance)
            if (math.abs(NumberValue - CloseTo) < Tolerance) then
                return true, EMPTY_STRING
            end

            return false, "Expected " .. tostring(CloseTo) .. " +/- " .. tostring(Tolerance) .. ", got " .. tostring(NumberValue)
        end, CloseTo, Tolerance)
    end

    TypeGuard.Number = Number
    TypeGuard.number = Number
end




do
    type StringTypeChecker = TypeChecker<StringTypeChecker> & {
        MinLength: SelfReturn<StringTypeChecker, number | (any?) -> number>;
        minLength: SelfReturn<StringTypeChecker, number | (any?) -> number>;

        MaxLength: SelfReturn<StringTypeChecker, number | (any?) -> number>;
        maxLength: SelfReturn<StringTypeChecker, number | (any?) -> number>;

        Pattern: SelfReturn<StringTypeChecker, string | (any?) -> string>;
        pattern: SelfReturn<StringTypeChecker, string | (any?) -> string>;

        Contains: SelfReturn<StringTypeChecker, string | (any?) -> string>;
        contains: SelfReturn<StringTypeChecker, string | (any?) -> string>;
    };

    local String: TypeCheckerConstructor<StringTypeChecker, TypeChecker<any>?>, StringClass = TypeGuard.Template("String")
    StringClass._Initial = CreateStandardInitial(TYPE_STRING)

    --- Ensures a string is at least a certain length
    function StringClass:MinLength(MinLength)
        ExpectType(MinLength, EXPECT_NUMBER_OR_FUNCTION, 1)

        return self:_AddConstraint(true, "MinLength", function(_, Item, MinLength)
            if (#Item < MinLength) then
                return false, "Length must be at least " .. MinLength .. ", got " .. #Item
            end

            return true, EMPTY_STRING
        end, MinLength)
    end
    StringClass.minLength = StringClass.MinLength

    --- Ensures a string is at most a certain length
    function StringClass:MaxLength(MaxLength)
        ExpectType(MaxLength, EXPECT_NUMBER_OR_FUNCTION, 1)

        return self:_AddConstraint(true, "MaxLength", function(_, Item, MaxLength)
            if (#Item > MaxLength) then
                return false, "Length must be at most " .. MaxLength .. ", got " .. #Item
            end

            return true, EMPTY_STRING
        end, MaxLength)
    end
    StringClass.maxLength = StringClass.MaxLength

    --- Ensures a string matches a pattern
    function StringClass:Pattern(PatternString)
        ExpectType(PatternString, EXPECT_STRING_OR_FUNCTION, 1)

        return self:_AddConstraint(false, "Pattern", function(_, Item, Pattern)
            if (string.match(Item, Pattern) ~= Item) then
                return false, "String does not match pattern " .. tostring(Pattern)
            end

            return true, EMPTY_STRING
        end, PatternString)
    end
    StringClass.pattern = StringClass.Pattern

    --- Ensures a string contains a certain substring
    function StringClass:Contains(SubstringValue)
        ExpectType(SubstringValue, EXPECT_STRING_OR_FUNCTION, 1)

        return self:_AddConstraint(false, "Contains", function(_, Item, Substring)
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
        OfLength: SelfReturn<ArrayTypeChecker, number | (any?) -> number>;
        ofLength: SelfReturn<ArrayTypeChecker, number | (any?) -> number>;

        MinLength: SelfReturn<ArrayTypeChecker, number | (any?) -> number>;
        minLength: SelfReturn<ArrayTypeChecker, number | (any?) -> number>;

        MaxLength: SelfReturn<ArrayTypeChecker, number | (any?) -> number>;
        maxLength: SelfReturn<ArrayTypeChecker, number | (any?) -> number>;

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

        IsFrozen: SelfReturn<ArrayTypeChecker>;
        isFrozen: SelfReturn<ArrayTypeChecker>;

        IsOrdered: SelfReturn<ArrayTypeChecker, boolean | (any?) -> boolean>;
        isOrdered: SelfReturn<ArrayTypeChecker, boolean | (any?) -> boolean>;
    };

    local Array: TypeCheckerConstructor<ArrayTypeChecker, TypeChecker<any>?>, ArrayClass = TypeGuard.Template("Array")

    function ArrayClass:_PrefixError(ErrorString: string, Index: number)
        return ErrorString:format((self._Tags.DenoteParams and PREFIX_PARAM or PREFIX_ARRAY), Index)
    end

    function ArrayClass:_Initial(TargetArray)
        if (typeof(TargetArray) ~= TYPE_TABLE) then
            return false, "Expected table, got " .. typeof(TargetArray)
        end

        for Key in TargetArray do
            local KeyType = typeof(Key)

            if (KeyType ~= TYPE_NUMBER) then
                return false, "Non-numetic key detected: " .. KeyType
            end
        end

        return true, EMPTY_STRING
    end

    --- Ensures an array is of a certain length
    function ArrayClass:OfLength(Length)
        ExpectType(Length, EXPECT_NUMBER_OR_FUNCTION, 1)

        return self:_AddConstraint(true, "Length", function(_, TargetArray, Length)
            if (#TargetArray ~= Length) then
                return false, "Length must be " .. Length .. ", got " .. #TargetArray
            end

            return true, EMPTY_STRING
        end, Length)
    end
    ArrayClass.ofLength = ArrayClass.OfLength

    --- Ensures an array is at least a certain length
    function ArrayClass:MinLength(MinLength)
        ExpectType(MinLength, EXPECT_NUMBER_OR_FUNCTION, 1)

        return self:_AddConstraint(true, "MinLength", function(_, TargetArray, MinLength)
            if (#TargetArray < MinLength) then
                return false, "Length must be at least " .. MinLength .. ", got " .. #TargetArray
            end

            return true, EMPTY_STRING
        end, MinLength)
    end
    ArrayClass.minLength = ArrayClass.MinLength

    --- Ensures an array is at most a certain length
    function ArrayClass:MaxLength(MaxLength)
        ExpectType(MaxLength, EXPECT_NUMBER_OR_FUNCTION, 1)

        return self:_AddConstraint(true, "MaxLength", function(_, TargetArray, MaxLength)
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
            ExpectType(Value, EXPECT_SOMETHING, 1)
        end

        if (StartPoint) then
            ExpectType(StartPoint, EXPECT_NUMBER_OR_FUNCTION, 2)
        end

        return self:_AddConstraint(false, "Contains", function(_, TargetArray, Value, StartPoint)
            if (table.find(TargetArray, Value, StartPoint) == nil) then
                return false, "Value not found in array: " .. tostring(Value)
            end

            return true, EMPTY_STRING
        end, Value, StartPoint)
    end
    ArrayClass.contains = ArrayClass.Contains

    --- Ensures each value in the template array satisfies the passed TypeChecker
    function ArrayClass:OfType(SubType)
        TypeGuard._AssertIsTypeBase(SubType, 1)

        return self:_AddConstraint(true, "OfType", function(SelfRef, TargetArray, SubType)
            for Index, Value in TargetArray do
                local Success, SubMessage = SubType:_Check(Value)

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
        ExpectType(SubTypesAtPositions, EXPECT_TABLE, 1)

        -- Just in case the user does any weird mutation
        local SubTypesCopy = table.create(#SubTypesAtPositions)

        for Index, Value in SubTypesAtPositions do
            TypeGuard._AssertIsTypeBase(Value, Index)
            SubTypesCopy[Index] = Value
        end

        setmetatable(SubTypesCopy, STRUCTURE_TO_FLAT_STRING_MT)

        return self:_AddConstraint(true, "OfStructure", function(SelfRef, TargetArray, SubTypesAtPositions)
            -- Check all fields which should be in the object exist (unless optional) and the type check for each passes
            for Index, Checker in SubTypesAtPositions do
                local Success, SubMessage = Checker:_Check(TargetArray[Index])

                if (not Success) then
                    return false, SelfRef:_PrefixError(ERR_PREFIX, tostring(Index)) .. SubMessage
                end
            end

            -- Check there are no extra indexes which shouldn't be in the object
            if (SelfRef._Tags.Strict) then
                for Index in TargetArray do
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
        return self:_AddTag("Strict")
    end
    ArrayClass.strict = ArrayClass.Strict

    --- Tags this ArrayTypeChecker as a params call (just for better information when using TypeGuard.Params)
    function ArrayClass:DenoteParams()
        return self:_AddTag("DenoteParams")
    end
    ArrayClass.denoteParams = ArrayClass.DenoteParams

    --- Checks if an array is frozen
    function ArrayClass:IsFrozen()
        return self:_AddConstraint(true, "IsFrozen", function(_, TargetArray)
            if (table.isfrozen(TargetArray)) then
                return true, EMPTY_STRING
            end

            return false, "Table was not frozen"
        end)
    end
    ArrayClass.isFrozen = ArrayClass.IsFrozen

    --- Checks if an array is ordered
    --- @TODO If 'Descending' = false, assume ascending, but if 'Descending' = nil, assume ascending or descending from first 2 items in the array (accept ordering either way)
    function ArrayClass:IsOrdered(Descending)
        if (Descending ~= nil) then
            ExpectType(Descending, EXPECT_BOOLEAN_OR_FUNCTION, 1)
        end

        return self:_AddConstraint(true, "IsOrdered", function(_, TargetArray, Descending)
            local Ascending = not Descending
            local Size = #TargetArray

            if (Size == 1) then
                return true, EMPTY_STRING
            end

            local Last = TargetArray[1]

            for Index = 2, Size do
                local Current = TargetArray[Index]

                if (Descending and Last < Current) then
                    return false, "Array is not ordered descending at index " .. Index
                elseif (Ascending and Last > Current) then
                    return false, "Array is not ordered ascending at index " .. Index
                end

                Last = Current
            end

            return true, EMPTY_STRING
        end, Descending)
    end
    ArrayClass.isOrdered = ArrayClass.IsOrdered

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

        IsFrozen: SelfReturn<ObjectTypeChecker>;
        isFrozen: SelfReturn<ObjectTypeChecker>;

        CheckMetatable: SelfReturn<ObjectTypeChecker, TypeChecker<any>>;
        checkMetatable: SelfReturn<ObjectTypeChecker, TypeChecker<any>>;

        OfClass: SelfReturn<ObjectTypeChecker, any>;
        ofClass: SelfReturn<ObjectTypeChecker, any>;
    };

    local Object: TypeCheckerConstructor<ObjectTypeChecker, {[any]: TypeChecker<any>}?>, ObjectClass = TypeGuard.Template("Object")

    function ObjectClass:_Initial(TargetObject)
        if (typeof(TargetObject) ~= TYPE_TABLE) then
            return false, "Expected table, got " .. typeof(TargetObject)
        end

        for Key in TargetObject do
            if (typeof(Key) == TYPE_NUMBER) then
                return false, "Incorrect key type: number"
            end
        end

        return true, EMPTY_STRING
    end

    --- Ensures every key that exists in the subject also exists in the structure passed, optionally strict i.e. no extra key-value pairs
    function ObjectClass:OfStructure(OriginalSubTypes)
        ExpectType(OriginalSubTypes, EXPECT_TABLE, 1)

        -- Just in case the user does any weird mutation
        local SubTypesCopy = {}

        for Index, Value in OriginalSubTypes do
            TypeGuard._AssertIsTypeBase(Value, Index)
            SubTypesCopy[Index] = Value
        end

        setmetatable(SubTypesCopy, STRUCTURE_TO_FLAT_STRING_MT)

        return self:_AddConstraint(true, "OfStructure", function(SelfRef, StructureCopy, SubTypes)
            -- Check all fields which should be in the object exist (unless optional) and the type check for each passes
            for Key, Checker in SubTypes do
                local RespectiveValue = StructureCopy[Key]

                if (RespectiveValue == nil and not Checker._Tags.Optional) then
                    return false, "[Key '" .. tostring(Key) .. "'] is nil"
                end

                local Success, SubMessage = Checker:_Check(RespectiveValue)

                if (not Success) then
                    return false, "[Key '" .. tostring(Key) .. "'] " .. SubMessage
                end
            end

            -- Check there are no extra fields which shouldn't be in the object
            if (SelfRef._Tags.Strict) then
                for Key in StructureCopy do
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

        return self:_AddConstraint(true, "OfValueType", function(_, TargetArray, SubType)
            for Index, Value in TargetArray do
                local Success, SubMessage = SubType:_Check(Value)

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

        return self:_AddConstraint(true, "OfKeyType", function(_, TargetArray, SubType)
            for Key in TargetArray do
                local Success, SubMessage = SubType:_Check(Key)

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
        return self:_AddTag("Strict")
    end
    ObjectClass.strict = ObjectClass.Strict

    --- OfStructure but strict
    function ObjectClass:StructuralEquals(Structure)
        return self:OfStructure(Structure):Strict()
    end
    ObjectClass.structuralEquals = ObjectClass.StructuralEquals

    --- Checks if an object is frozen
    function ObjectClass:IsFrozen()
        return self:_AddConstraint(true, "IsFrozen", function(_, TargetObject)
            if (table.isfrozen(TargetObject)) then
                return true, EMPTY_STRING
            end

            return false, "Table was not frozen"
        end)
    end
    ObjectClass.isFrozen = ObjectClass.IsFrozen

    --- Checks an object's metatable
    function ObjectClass:CheckMetatable(Checker)
        TypeGuard._AssertIsTypeBase(Checker, 1)

        return self:_AddConstraint(true, "CheckMetatable", function(_, TargetObject, Checker)
            local Success, Message = Checker:Check(getmetatable(TargetObject))
            return Success, "[Metatable] " .. Message
        end, Checker)
    end
    ObjectClass.checkMetatable = ObjectClass.CheckMetatable

    --- Checks if an object's __index points to the specified class
    function ObjectClass:OfClass(Class)
        ExpectType(Class, EXPECT_TABLE, 1)
        assert(Class.__index, "Class must have an __index")

        return self:CheckMetatable(Object():Equals(Class))
    end

    ObjectClass._InitialConstraint = ObjectClass.OfStructure

    TypeGuard.Object = Object
end




do
    type InstanceTypeChecker = TypeChecker<InstanceTypeChecker> & {
        OfStructure: SelfReturn<InstanceTypeChecker, {[any]: TypeChecker<Instance>}>;
        ofStructure: SelfReturn<InstanceTypeChecker, {[any]: TypeChecker<Instance>}>;

        StructuralEquals: SelfReturn<InstanceTypeChecker, {[any]: TypeChecker<Instance>}>;
        structuralEquals: SelfReturn<InstanceTypeChecker, {[any]: TypeChecker<Instance>}>;

        IsA: SelfReturn<InstanceTypeChecker, string | (any?) -> string>;
        isA: SelfReturn<InstanceTypeChecker, string | (any?) -> string>;

        Strict: SelfReturn<InstanceTypeChecker>;
        strict: SelfReturn<InstanceTypeChecker>;

        IsDescendantOf: SelfReturn<InstanceTypeChecker, Instance | (any?) -> Instance>;
        isDescendantOf: SelfReturn<InstanceTypeChecker, Instance | (any?) -> Instance>;

        IsAncestorOf: SelfReturn<InstanceTypeChecker, Instance | (any?) -> Instance>;
        isAncestorOf: SelfReturn<InstanceTypeChecker, Instance | (any?) -> Instance>;

        HasTag: SelfReturn<InstanceTypeChecker, string | (any?) -> string>;
        hasTag: SelfReturn<InstanceTypeChecker, string | (any?) -> string>;

        HasAttribute: SelfReturn<InstanceTypeChecker, string | (any?) -> string>;
        hasAttribute: SelfReturn<InstanceTypeChecker, string | (any?) -> string>;

        CheckAttribute: SelfReturn<InstanceTypeChecker, string, TypeChecker<any>>;
        checkAttribute: SelfReturn<InstanceTypeChecker, string, TypeChecker<any>>;

        HasTags: SelfReturn<InstanceTypeChecker, {string} | (any?) -> {string}>;
        hasTags: SelfReturn<InstanceTypeChecker, {string} | (any?) -> {string}>;

        HasAttributes: SelfReturn<InstanceTypeChecker, {string} | (any?) -> {string}>;
        hasAttributes: SelfReturn<InstanceTypeChecker, {string} | (any?) -> {string}>;

        CheckAttributes: SelfReturn<InstanceTypeChecker, {[string]: TypeChecker<any>} | (any?) -> {[string]: TypeChecker<any>}>;
        checkAttributes: SelfReturn<InstanceTypeChecker, {[string]: TypeChecker<any>} | (any?) -> {[string]: TypeChecker<any>}>;
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

    local InstanceChecker: TypeCheckerConstructor<InstanceTypeChecker, string | (any?) -> string | nil, {[string]: TypeChecker<any>}?>, InstanceCheckerClass = TypeGuard.Template("Instance")
    InstanceCheckerClass._Initial = CreateStandardInitial(TYPE_INSTANCE)

    --- Ensures that an Instance has specific children and/or properties
    function InstanceCheckerClass:OfStructure(OriginalSubTypes)
        ExpectType(OriginalSubTypes, EXPECT_TABLE, 1)

        -- Just in case the user does any weird mutation
        local SubTypesCopy = {}

        for Key, Value in OriginalSubTypes do
            TypeGuard._AssertIsTypeBase(Value, Key)
            SubTypesCopy[Key] = Value
        end

        setmetatable(SubTypesCopy, STRUCTURE_TO_FLAT_STRING_MT)

        return self:_AddConstraint(true, "OfStructure", function(SelfRef, InstanceRoot, SubTypes)
            -- Check all properties and children which should be in the Instance exist (unless optional) and the type check for each passes
            for Key, Checker in SubTypes do
                local Value = TryGet(InstanceRoot, Key)
                local Success, SubMessage = Checker:_Check(Value)

                if (not Success) then
                    return false, (typeof(Value) == TYPE_INSTANCE and "[Instance '" or "[Property '") .. tostring(Key) .. "'] " .. SubMessage
                end
            end

            -- Check there are no extra children which shouldn't be in the Instance
            if (SelfRef._Tags.Strict) then
                for _, Value in InstanceRoot:GetChildren() do
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
    InstanceCheckerClass.ofStructure = InstanceCheckerClass.OfStructur

    --- Uses Instance.IsA to assert the type of an Instance
    function InstanceCheckerClass:IsA(InstanceIsA)
        ExpectType(InstanceIsA, EXPECT_STRING_OR_FUNCTION, 1)

        return self:_AddConstraint(true, "IsA", function(_, InstanceRoot, InstanceIsA)
            if (not InstanceRoot:IsA(InstanceIsA)) then
                return false, "Expected " .. InstanceIsA .. ", got " .. InstanceRoot.ClassName
            end

            return true, EMPTY_STRING
        end, InstanceIsA)
    end
    InstanceCheckerClass.isA = InstanceCheckerClass.IsA

    --- Activates strict tag for OfStructure
    function InstanceCheckerClass:Strict()
        return self:_AddTag("Strict")
    end
    InstanceCheckerClass.strict = InstanceCheckerClass.Strict

    --- OfStructure + strict tag i.e. no extra children exist beyond what is specified
    function InstanceCheckerClass:StructuralEquals(Structure)
        return self:OfStructure(Structure):Strict()
    end
    InstanceCheckerClass.structuralEquals = InstanceCheckerClass.StructuralEquals

    --- Checks if an Instance has a particular tag
    function InstanceCheckerClass:HasTag(Tag: string)
        ExpectType(Tag, EXPECT_STRING_OR_FUNCTION, 1)

        return self:_AddConstraint(false, "HasTag", function(_, InstanceRoot, Tag)
            if (CollectionService:HasTag(InstanceRoot, Tag)) then
                return true, EMPTY_STRING
            end

            return false, "Expected tag '" .. Tag .. "' on Instance " .. InstanceRoot:GetFullName()
        end, Tag)
    end
    InstanceCheckerClass.hasTag = InstanceCheckerClass.HasTag

    --- Checks if an Instance has a particular attribute
    function InstanceCheckerClass:HasAttribute(Attribute: string)
        ExpectType(Attribute, EXPECT_STRING_OR_FUNCTION, 1)

        return self:_AddConstraint(false, "HasAttribute", function(_, InstanceRoot, Attribute)
            if (InstanceRoot:GetAttribute(Attribute) ~= nil) then
                return true, EMPTY_STRING
            end

            return false, "Expected attribute '" .. Attribute .. "' to exist on Instance " .. InstanceRoot:GetFullName()
        end, Attribute)
    end
    InstanceCheckerClass.hasAttribute = InstanceCheckerClass.HasAttribute

    --- Applies a TypeChecker to an Instance's expected attribute
    function InstanceCheckerClass:CheckAttribute(Attribute: string, Checker: TypeChecker<any>)
        ExpectType(Attribute, EXPECT_STRING_OR_FUNCTION, 1)
        TypeGuard._AssertIsTypeBase(Checker, 2)

        return self:_AddConstraint(false, "CheckAttribute", function(_, InstanceRoot, Attribute)
            local Success, SubMessage = Checker:_Check(InstanceRoot:GetAttribute(Attribute))

            if (not Success) then
                return false, "Attribute '" .. Attribute .. "' not satisfied on Instance " .. InstanceRoot:GetFullName() .. ": " .. SubMessage
            end

            return true, EMPTY_STRING
        end, Attribute, Checker)
    end
    InstanceCheckerClass.checkAttribute = InstanceCheckerClass.CheckAttribute





    --- Checks if an Instance has a set of tags
    function InstanceCheckerClass:HasTags(Tags: {string})
        ExpectType(Tags, EXPECT_TABLE_OR_FUNCTION, 1)

        if (typeof(Tags) == TYPE_TABLE) then
            for Index, Tag in Tags do
                assert(typeof(Tag) == "string", "Expected tag #" .. Index .. " to be a string")
            end
        end

        return self:_AddConstraint(false, "HasTags", function(_, InstanceRoot, Tags)
            for _, Tag in Tags do
                if (not CollectionService:HasTag(InstanceRoot, Tag)) then
                    return false, "Expected tag '" .. Tag .. "' on Instance " .. InstanceRoot:GetFullName()
                end
            end

            return true, EMPTY_STRING
        end, Tags)
    end
    InstanceCheckerClass.hasTags = InstanceCheckerClass.HasTags

    --- Checks if an Instance has a set of attributes
    function InstanceCheckerClass:HasAttributes(Attributes: {string})
        ExpectType(Attributes, EXPECT_TABLE_OR_FUNCTION, 1)

        if (typeof(Attributes) == TYPE_TABLE) then
            for Index, Attribute in Attributes do
                assert(typeof(Attribute) == "string", "Expected attribute #" .. Index .. " to be a string")
            end
        end

        return self:_AddConstraint(false, "HasAttributes", function(_, InstanceRoot, Attributes)
            for _, Attribute in Attributes do
                if (InstanceRoot:GetAttribute(Attribute) == nil) then
                    return false, "Expected attribute '" .. Attribute .. "' to exist on Instance " .. InstanceRoot:GetFullName()
                end
            end

            return true, EMPTY_STRING
        end, Attributes)
    end
    InstanceCheckerClass.hasAttributes = InstanceCheckerClass.HasAttributes

    --- Applies a TypeChecker to an Instance's expected attribute
    function InstanceCheckerClass:CheckAttributes(AttributeCheckers: {TypeChecker<any>})
        ExpectType(AttributeCheckers, EXPECT_TABLE, 1)

        for Attribute, Checker in AttributeCheckers do
            assert(typeof(Attribute) == "string", "Attribute '" .. tostring(Attribute) .. "' was not a string")
            TypeGuard._AssertIsTypeBase(Checker, "")
        end

        return self:_AddConstraint(false, "CheckAttributes", function(_, InstanceRoot, AttributeCheckers)
            for Attribute, Checker in AttributeCheckers do
                local Success, SubMessage = Checker:_Check(InstanceRoot:GetAttribute(Attribute))

                if (not Success) then
                    return false, "Attribute '" .. Attribute .. "' not satisfied on Instance " .. InstanceRoot:GetFullName() .. ": " .. SubMessage
                end
            end

            return true, EMPTY_STRING
        end, AttributeCheckers)
    end
    InstanceCheckerClass.checkAttributes = InstanceCheckerClass.CheckAttributes

    --- Checks if an Instance is a descendant of a particular Instance
    function InstanceCheckerClass:IsDescendantOf(Instance)
        ExpectType(Instance, EXPECT_INSTANCE_OR_FUNCTION, 1)

        return self:_AddConstraint(true, "IsDescendantOf", function(_, SubjectInstance, Instance)
            if (SubjectInstance:IsDescendantOf(Instance)) then
                return true, EMPTY_STRING
            end

            return false, "Expected Instance " .. SubjectInstance:GetFullName() .. " to be a descendant of " .. Instance:GetFullName()
        end, Instance)
    end
    InstanceCheckerClass.isDescendantOf = InstanceCheckerClass.IsDescendantOf

    --- Checks if an Instance is an ancestor of a particular Instance
    function InstanceCheckerClass:IsAncestorOf(Instance)
        ExpectType(Instance, EXPECT_INSTANCE_OR_FUNCTION, 1)

        return self:_AddConstraint(false, "IsAncestorOf", function(_, SubjectInstance, Instance)
            if (SubjectInstance:IsAncestorOf(Instance)) then
                return true, EMPTY_STRING
            end

            return false, "Expected Instance " .. SubjectInstance:GetFullName() .. " to be an ancestor of " .. Instance:GetFullName()
        end, Instance)
    end
    InstanceCheckerClass.isAncestorOf = InstanceCheckerClass.IsAncestorOf

    --- Checks if a particular child exists in an Instance
    function InstanceCheckerClass:HasChild(Name)
        ExpectType(Name, EXPECT_STRING_OR_FUNCTION, 1)

        return self:_AddConstraint(false, "HasChild", function(_, InstanceRoot, Name)
            if (InstanceRoot:FindFirstChild(Name)) then
                return true, EMPTY_STRING
            end

            return false, "Expected child '" .. Name .. "' to exist on Instance " .. InstanceRoot:GetFullName()
        end, Name)
    end

    InstanceCheckerClass._InitialConstraints = {InstanceCheckerClass.IsA, InstanceCheckerClass.OfStructure}

    TypeGuard.Instance = InstanceChecker
end




do
    type BooleanTypeChecker = TypeChecker<BooleanTypeChecker> & {};

    local Boolean: TypeCheckerConstructor<BooleanTypeChecker, boolean?>, BooleanClass = TypeGuard.Template("Boolean")
    BooleanClass._Initial = CreateStandardInitial(TYPE_BOOLEAN)

    BooleanClass._InitialConstraint = BooleanClass.Equals

    TypeGuard.Boolean = Boolean
    TypeGuard.boolean = Boolean
end




do
    type EnumTypeChecker = TypeChecker<EnumTypeChecker> & {
        IsA: SelfReturn<EnumTypeChecker, Enum | EnumItem | (any?) -> Enum | EnumItem>;
        isA: SelfReturn<EnumTypeChecker, Enum | EnumItem | (any?) -> Enum | EnumItem>;
    };

    local EnumChecker: TypeCheckerConstructor<EnumTypeChecker>, EnumCheckerClass = TypeGuard.Template("Enum")

    function EnumCheckerClass:_Initial(Value)
        local GotType = typeof(Value)

        if (GotType ~= TYPE_ENUM_ITEM and GotType ~= TYPE_ENUM) then
            return false, "Expected EnumItem or Enum, got " .. GotType
        end

        return true, EMPTY_STRING
    end

    --- Ensures that a passed EnumItem is either equivalent to an EnumItem or a sub-item of an Enum class
    function EnumCheckerClass:IsA(TargetEnum)
        ExpectType(TargetEnum, EXPECT_ENUM_OR_ENUM_ITEM_OR_FUNCTION, 1)

        return self:_AddConstraint(true, "IsA", function(_, Value, TargetEnum)
            local TargetType = typeof(TargetEnum)

            -- Both are EnumItems
            if (TargetType == TYPE_ENUM_ITEM) then
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
    type ThreadTypeChecker = TypeChecker<ThreadTypeChecker> & {
        IsDead: SelfReturn<ThreadTypeChecker>;
        isDead: SelfReturn<ThreadTypeChecker>;

        IsSuspended: SelfReturn<ThreadTypeChecker>;
        isSuspended: SelfReturn<ThreadTypeChecker>;

        IsRunning: SelfReturn<ThreadTypeChecker>;
        isRunning: SelfReturn<ThreadTypeChecker>;

        IsNormal: SelfReturn<ThreadTypeChecker>;
        isNormal: SelfReturn<ThreadTypeChecker>;

        HasStatus: SelfReturn<ThreadTypeChecker, string | (any?) -> string>;
        hasStatus: SelfReturn<ThreadTypeChecker, string | (any?) -> string>;
    };

    local ThreadChecker: TypeCheckerConstructor<ThreadTypeChecker>, ThreadCheckerClass = TypeGuard.Template("Thread")
    ThreadCheckerClass._Initial = CreateStandardInitial(TYPE_THREAD)

    function ThreadCheckerClass:IsDead()
        return self:HasStatus("dead"):_AddTag("StatusCheck")
    end

    function ThreadCheckerClass:IsSuspended()
        return self:HasStatus("suspended"):_AddTag("StatusCheck")
    end

    function ThreadCheckerClass:IsRunning()
        return self:HasStatus("running"):_AddTag("StatusCheck")
    end

    function ThreadCheckerClass:IsNormal()
        return self:HasStatus("normal"):_AddTag("StatusCheck")
    end

    --- Checks the coroutine's status against a given status string
    function ThreadCheckerClass:HasStatus(Status)
        ExpectType(Status, EXPECT_STRING_OR_FUNCTION, 1)

        return self:_AddConstraint(true, "HasStatus", function(_, Thread, Status)
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




do
    type AnyTypeChecker = TypeChecker<AnyTypeChecker> & {}

    local AnyChecker: TypeCheckerConstructor<AnyTypeChecker>, AnyCheckerClass = TypeGuard.Template("Any")
    function AnyCheckerClass:_Initial(Item)
        if (Item == nil) then
            return false, "Expected something, got nil"
        end

        return true, EMPTY_STRING
    end

    TypeGuard.Any = AnyChecker
    TypeGuard.any = AnyChecker
end




-- Luau data types
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

-- Extra base Lua data types
TypeGuard.Function = TypeGuard.FromTypeName(TYPE_FUNCTION)
TypeGuard[TYPE_FUNCTION] = TypeGuard.Function

TypeGuard.Userdata = TypeGuard.FromTypeName(TYPE_USERDATA)
TypeGuard[TYPE_USERDATA] = TypeGuard.Userdata

TypeGuard.Nil = TypeGuard.FromTypeName(TYPE_NIL)
TypeGuard[TYPE_NIL] = TypeGuard.Nil

--- Creates a function which checks params as if they were a strict Array checker
function TypeGuard.Params(...: TypeChecker<any>)
    local Args = {...}
    local ArgSize = #Args

    for Index, ParamChecker in Args do
        TypeGuard._AssertIsTypeBase(ParamChecker, Index)
    end

    return function(...)
        local Size = select("#", ...)

        if (ArgSize ~= Size) then
            error("Expected " .. ArgSize .. " argument" .. (ArgSize == 1 and "" or "s") .. ", got " .. Size)
        end

        for Index = 1, Size do
            local Success, Message = Args[Index]:Check(select(Index, ...))

            if (not Success) then
                error("Invalid argument #" .. Index .. " (" .. Message .. ")")
            end
        end
    end
end
TypeGuard.params = TypeGuard.Params

--- Creates a function which checks variadic params against a single given TypeChecker
function TypeGuard.VariadicParams(CompareType: TypeChecker<any>)
    TypeGuard._AssertIsTypeBase(CompareType, 1)

    return function(...)
        local Size = select("#", ...)

        for Index = 1, Size do
            local Success, Message = CompareType:Check(select(Index, ...))

            if (not Success) then
                error("Invalid argument #" .. Index .. " (" .. Message .. ")")
            end
        end
    end
end
TypeGuard.variadicParams = TypeGuard.VariadicParams

--- Creates a function which checks params as if they were a strict Array checker, using context as the first param; context is passed down to functional constraint args
function TypeGuard.ParamsWithContext(...: TypeChecker<any>)
    local Args = {...}
    local ArgSize = #Args

    for Index, ParamChecker in Args do
        TypeGuard._AssertIsTypeBase(ParamChecker, Index)
    end

    return function(Context: any?, ...)
        local Size = select("#", ...)

        if (ArgSize ~= Size) then
            error("Expected " .. ArgSize .. " argument" .. (ArgSize == 1 and "" or "s") .. ", got " .. Size)
        end

        for Index = 1, Size do
            local Success, Message = Args[Index]:WithContext(Context):Check(select(Index, ...))

            if (not Success) then
                error("Invalid argument #" .. Index .. " (" .. Message .. ")")
            end
        end
    end
end

--- Creates a function which checks variadic params against a single given TypeChecker, using context as the first param; context is passed down to functional constraint args
function TypeGuard.VariadicParamsWithContext(CompareType: TypeChecker<any>)
    TypeGuard._AssertIsTypeBase(CompareType, 1)

    return function(Context: any?, ...)
        local Size = select("#", ...)

        for Index = 1, Size do
            local Success, Message = CompareType:WithContext(Context):Check(select(Index, ...))

            if (not Success) then
                error("Invalid argument #" .. Index .. " (" .. Message .. ")")
            end
        end
    end
end

--- Wraps a function in a param checker function
function TypeGuard.WrapFunctionParams(Call: (...any) -> (...any), ...: TypeChecker<any>)
    ExpectType(Call, EXPECT_FUNCTION, 1)

    for Index = 1, select("#", ...) do
        TypeGuard._AssertIsTypeBase(select(Index, ...), Index)
    end

    local ParamChecker = TypeGuard.Params(...)

    return function(...)
        ParamChecker(...)
        return Call(...)
    end
end

--- Wraps a function in a variadic param checker function
function TypeGuard.WrapFunctionVariadicParams(Call: (...any) -> (...any), VariadicParamType: TypeChecker<any>)
    ExpectType(Call, EXPECT_FUNCTION, 1)
    TypeGuard._AssertIsTypeBase(VariadicParamType, 2)

    local ParamChecker = TypeGuard.VariadicParams(VariadicParamType)

    return function(...)
        ParamChecker(...)
        return Call(...)
    end
end

return TypeGuard