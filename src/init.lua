--!nonstrict

-- TODOs:
-- .. This script really needs splitting into sub-modules
-- .. Design some way to turn on and off different levels of runtime type checking for production vs development - for performance
-- .. Auto-template for objects, arrays, and Instances, e.g. -- TypeGuard.Object():FromSample({ P = 1, Q = 2, R = {X = "s", ...} })

local CollectionService = game:GetService("CollectionService")

-- Cache up here so these arrays aren't re-created with every function call for the simple checking system
local EXPECT_ENUM_OR_ENUM_ITEM_OR_FUNCTION = {"Enum", "EnumItem", "function"}
local EXPECT_INSTANCE_OR_FUNCTION = {"Instance", "function"}
local EXPECT_BOOLEAN_OR_FUNCTION = {"boolean", "function"}
local EXPECT_STRING_OR_FUNCTION = {"string", "function"}
local EXPECT_NUMBER_OR_FUNCTION = {"number", "function"}
local EXPECT_TABLE_OR_FUNCTION = {"table", "function"}
local EXPECT_SOMETHING = {"something"}
local EXPECT_FUNCTION = {"function"}
local EXPECT_BOOLEAN = {"boolean"}
local EXPECT_STRING = {"string"}
local EXPECT_TABLE = {"table"}

--- This is only really for type checking internally for data passed to constraints and util functions
local function ExpectType(Target: any, ExpectedTypes: {string}, ArgKey: number | string)
    local GotType = typeof(Target)
    local Satisfied = false

    for _, PossibleType in ExpectedTypes do
        if (GotType == PossibleType) then
            Satisfied = true
            return
        end
    end

    if (not Satisfied) then
        error((`Invalid argument #{ArgKey} ({table.concat(ExpectedTypes, " or ")} expected, got {GotType})`))
    end
end

local function CreateStandardInitial(ExpectedTypeName: string): ((...any) -> (boolean, string?))
    return function(Item)
        local ItemType = typeof(Item)

        if (ItemType == ExpectedTypeName) then
            return true
        end

        return false, `Expected {ExpectedTypeName}, got {ItemType}.`
    end
end

local function ConcatWithToString(Array: {any}, Separator: string): string
    local Result = ""

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

local WEAK_KEY_MT = {__mode = "ks"}

-- Standard re-usable functions throughout all TypeCheckers
local function IsAKeyIn(self, Store)
    ExpectType(Store, EXPECT_TABLE_OR_FUNCTION, 1)

    return self:_AddConstraint(false, "IsAKeyIn", function(_, Key, Store)
        if (Store[Key] == nil) then
            local Keys = {}

            for Key in Store do
                table.insert(Keys, Key)
            end

            return false, `Key {Key} was not found in set ({ConcatWithToString(Keys, ", ")})`
        end

        return true
    end, Store)
end

local function IsAValueIn(self, Store)
    ExpectType(Store, EXPECT_TABLE_OR_FUNCTION, 1)

    return self:_AddConstraint(false, "IsAValueIn", function(_, TargetValue, Store)
        for _, Value in Store do
            if (Value == TargetValue) then
                return true
            end
        end

        return false, `Value {TargetValue} was not found in table {Store}`
    end, Store)
end

local function Equals(self, ExpectedValue)
    return self:_AddConstraint(true, "Equals", function(_, Value, ExpectedValue)
        if (Value == ExpectedValue) then
            return true
        end

        return false, `Value {Value} does not equal {ExpectedValue}`
    end, ExpectedValue)
end

local function GreaterThan(self, GTValue)
    return self:_AddConstraint(true, "GreaterThan", function(_, Value, GTValue)
        if (Value > GTValue) then
            return true
        end

        return false, `Value {Value} is not greater than {GTValue}`
    end, GTValue)
end

local function LessThan(self, LTValue)
    return self:_AddConstraint(true, "LessThan", function(_, Value, LTValue)
        if (Value < LTValue) then
            return true
        end

        return false, `Value {Value} is not less than {LTValue}`
    end, LTValue)
end

local function GreaterThanOrEqualTo(self, GTEValue)
    return self:_AddConstraint(true, "GreaterThanOrEqualTo", function(_, Value, GTEValue)
        if (Value >= GTEValue) then
            return true
        end

        return false, `Value {Value} is not greater than or equal to {GTEValue}.`
    end, GTEValue)
end

local function LessThanOrEqualTo(self, LTEValue)
    return self:_AddConstraint(true, "LessThanOrEqualTo", function(_, Value, LTEValue)
        if (Value <= LTEValue) then
            return true
        end

        return false, `Value {Value} is not less than or equal to {LTEValue}.`
    end, LTEValue)
end

type AnyMethod = (...any) -> (...any)

type SignatureTypeCheckerInternal = {
    IsTemplate: true;

    Or: AnyMethod;
    alternate: AnyMethod;
    And: AnyMethod;
    additional: AnyMethod;
    Copy: AnyMethod;
    copy: AnyMethod;
    Alias: AnyMethod;
    alias: AnyMethod;
    Negate: AnyMethod;
    negate: AnyMethod;
    Cached: AnyMethod;
    cached: AnyMethod;
    Optional: AnyMethod;
    optional: AnyMethod;
    WithContext: AnyMethod;
    withContext: AnyMethod;
    FailMessage: AnyMethod;
    failMessage: AnyMethod;
    WrapCheck: AnyMethod;
    wrapCheck: AnyMethod;
    WrapAssert: AnyMethod;
    wrapAssert: AnyMethod;
    Check: AnyMethod;
    check: AnyMethod;
    Assert: AnyMethod;
    assert: AnyMethod;
    Equals: AnyMethod;
    equals: AnyMethod;
    IsAValueIn: AnyMethod;
    isAValueIn: AnyMethod;
    IsAKeyIn: AnyMethod;
    isAKeyIn: AnyMethod;
    GreaterThan: AnyMethod;
    greaterThan: AnyMethod;
    LessThan: AnyMethod;
    lessThan: AnyMethod;
    GreaterThanOrEqualTo: AnyMethod;
    greaterThanOrEqualTo: AnyMethod;
    LessThanOrEqualTo: AnyMethod;
    lessThanOrEqualTo: AnyMethod;
    _AddConstraint: AnyMethod;
    _AddTag: AnyMethod;
    _CreateCache: AnyMethod;
    _Check: AnyMethod;
}

type SignatureTypeChecker = {
    IsTemplate: true;
}

type SelfReturn<T, P...> = ((T, P...) -> T)

type TypeCheckerConstructor<T, P...> = ((P...) -> T)

-- Base methods
type TC_Or<ExtensionClass> = SelfReturn<ExtensionClass, SignatureTypeChecker | () -> SignatureTypeChecker>;
type TC_And<ExtensionClass> = SelfReturn<ExtensionClass, SignatureTypeChecker>;
type TC_Copy<ExtensionClass> = SelfReturn<ExtensionClass>;
type TC_Alias<ExtensionClass> = SelfReturn<ExtensionClass, string>;
type TC_Negate<ExtensionClass> = SelfReturn<ExtensionClass>;
type TC_Cached<ExtensionClass> = SelfReturn<ExtensionClass>;
type TC_Optional<ExtensionClass> = SelfReturn<ExtensionClass>;
type TC_WithContext<ExtensionClass> = SelfReturn<ExtensionClass, any?>;
type TC_FailMessage<ExtensionClass> = SelfReturn<ExtensionClass, string>;
type TC_WrapCheck<ExtensionClass> = (ExtensionClass) -> ((any?) -> (boolean, string?));
type TC_WrapAssert<ExtensionClass> = (ExtensionClass) -> ((any?) -> ());
type TC_Check<ExtensionClass> = (ExtensionClass, any) -> (boolean, string?);
type TC_Assert<ExtensionClass> = (ExtensionClass, any) -> ();

-- Base constraints
type TC_Equals<ExtensionClass> = SelfReturn<ExtensionClass, any | ((any?) -> any)>;
type TC_IsAValueIn<ExtensionClass> = SelfReturn<ExtensionClass, any | ((any?) -> any)>;
type TC_IsAKeyIn<ExtensionClass> = SelfReturn<ExtensionClass, any | ((any?) -> any)>;
type TC_GreaterThan<ExtensionClass, Primitive> = SelfReturn<ExtensionClass, Primitive | ((any?) -> Primitive)>;
type TC_LessThan<ExtensionClass, Primitive> = SelfReturn<ExtensionClass, Primitive | ((any?) -> Primitive)>;
type TC_GreaterThanOrEqualTo<ExtensionClass, Primitive> = SelfReturn<ExtensionClass, Primitive | ((any?) -> Primitive)>;
type TC_LessThanOrEqualTo<ExtensionClass, Primitive> = SelfReturn<ExtensionClass, Primitive | ((any?) -> Primitive)>;

type TypeChecker<ExtensionClass, Primitive> = {
    IsTemplate: true;

    -- Methods available in all TypeCheckers
    Or: TC_Or<ExtensionClass>;
    alternate: TC_Or<ExtensionClass>;
    
    And: TC_And<ExtensionClass>;
    additional: TC_Or<ExtensionClass>;

    Copy: TC_Copy<ExtensionClass>;
    copy: TC_Copy<ExtensionClass>;

    Alias: TC_Alias<ExtensionClass>;
    alias: TC_Alias<ExtensionClass>;

    Negate: TC_Negate<ExtensionClass>;
    negate: TC_Negate<ExtensionClass>;

    Cached: TC_Cached<ExtensionClass>;
    cached: TC_Cached<ExtensionClass>;

    Optional: TC_Optional<ExtensionClass>;
    optional: TC_Optional<ExtensionClass>;

    WithContext: TC_WithContext<ExtensionClass>;
    withContext: TC_WithContext<ExtensionClass>;

    FailMessage: TC_FailMessage<ExtensionClass>;
    failMessage: TC_FailMessage<ExtensionClass>;

    WrapCheck: TC_WrapCheck<ExtensionClass>;
    wrapCheck: TC_WrapCheck<ExtensionClass>;

    WrapAssert: TC_WrapAssert<ExtensionClass>;
    wrapAssert: TC_WrapAssert<ExtensionClass>;

    Check: TC_Check<ExtensionClass>;
    check: TC_Check<ExtensionClass>;

    Assert: TC_Assert<ExtensionClass>;
    assert: TC_Assert<ExtensionClass>;

    -- Constraint methods available in all TypeCheckers
    Equals: TC_Equals<ExtensionClass>;
    equals: TC_Equals<ExtensionClass>;

    IsAValueIn: TC_IsAValueIn<ExtensionClass>;
    isAValueIn: TC_IsAValueIn<ExtensionClass>;

    IsAKeyIn: TC_IsAKeyIn<ExtensionClass>;
    isAKeyIn: TC_IsAKeyIn<ExtensionClass>;

    GreaterThan: TC_GreaterThan<ExtensionClass, Primitive>;
    greaterThan: TC_GreaterThan<ExtensionClass, Primitive>;

    LessThan: TC_LessThan<ExtensionClass, Primitive>;
    lessThan: TC_LessThan<ExtensionClass, Primitive>;

    GreaterThanOrEqualTo: TC_GreaterThanOrEqualTo<ExtensionClass, Primitive>;
    greaterThanOrEqualTo: TC_GreaterThanOrEqualTo<ExtensionClass, Primitive>;

    LessThanOrEqualTo: TC_LessThanOrEqualTo<ExtensionClass, Primitive>;
    lessThanOrEqualTo: TC_LessThanOrEqualTo<ExtensionClass, Primitive>;
};

local ScriptNameToContextEnabled = {}
local NegativeCacheValue = {} -- Exists for Cached() because nil causes problems
local RootContext -- Faster & easier just using one high scope variable which all TypeCheckers can access during checking time, than propogating the context downwards
local TypeGuard = {}

--- Creates a template TypeChecker object that can be used to extend behaviors via constraints
function TypeGuard.Template(Name: string)
    ExpectType(Name, EXPECT_STRING, 1)

    local TemplateClass = {}
    TemplateClass.__index = TemplateClass
    TemplateClass.InitialConstraintsVariadic = nil
    TemplateClass.InitialConstraints = nil
    TemplateClass.InitialConstraint = nil
    TemplateClass.IsTemplate = true
    TemplateClass.Type = Name

    function TemplateClass.new(...)
        local self = {
            _Tags = {};
            _Disjunction = {};
            _Conjunction = {};
            _ActiveConstraints = {};

            _LastConstraint = "";

            _Cache = nil;
            _Context = nil;
            _FailMessage = nil;
        }

        setmetatable(self, TemplateClass)

        local NumArgs = select("#", ...)

        -- Support for a single constraint passed as the constructor, with an arbitrary number of args
        local InitialConstraint = self.InitialConstraint

        if (InitialConstraint and NumArgs > 0) then
            return InitialConstraint(self, ...)
        end

        -- Multiple constraints support (but only ONE arg per constraint is supported currently)
        local InitialConstraints = TemplateClass.InitialConstraints

        if (InitialConstraints and NumArgs > 0) then
            for Index = 1, NumArgs do
                self = InitialConstraints[Index](self, select(Index, ...))
            end

            return self
        end

        -- Variadic constraints support
        local InitialConstraintsVariadic = TemplateClass.InitialConstraintsVariadic

        if (InitialConstraintsVariadic and NumArgs > 0) then
            for Index = 1, NumArgs do
                self = InitialConstraintsVariadic(self, select(Index, ...))
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

        -- Copy or
        for Index, Disjunction in self._Disjunction do
            New._Disjunction[Index] = Disjunction
        end

        -- Copy and
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
        assert(LastConstraint ~= "", "Nothing to negate! (No constraints active)")
        self._ActiveConstraints[LastConstraint][4] = true

        return self
    end
    TemplateClass.negate = TemplateClass.Negate

    --- Sets a custom fail message to return if Check() fails. Accepts a function which passes the value and context as arguments.
    function TemplateClass:FailMessage(Message: string | ((any?, any?) -> (string)))
        ExpectType(Message, EXPECT_STRING_OR_FUNCTION, 1)

        self = self:Copy()
        self._FailMessage = Message
        return self
    end
    TemplateClass.failMessage = TemplateClass.FailMessage

    function TemplateClass:Cached()
        return self:_AddTag("Cached")
    end
    TemplateClass.cached = TemplateClass.Cached

    function TemplateClass:_AddConstraint(AllowOnlyOne, ConstraintName, Constraint, ...)
        if (AllowOnlyOne ~= nil) then
            ExpectType(AllowOnlyOne, EXPECT_BOOLEAN, 1)
        end

        ExpectType(ConstraintName, EXPECT_STRING, 2)
        ExpectType(Constraint, EXPECT_FUNCTION, 3)

        self = self:Copy()

        local Args = {...}
        local HasFunctions = false

        for _, Value in Args do
            local ArgType = type(Value)

            if (ArgType == "function") then
                HasFunctions = true
                continue
            end
        end

        local ActiveConstraints = self._ActiveConstraints

        if (AllowOnlyOne) then
            local Found = false

            for _, ConstraintData in ActiveConstraints do
                if (ConstraintData[5] == ConstraintName) then
                    Found = true
                    break
                end
            end

            if (Found) then
                error(`Attempt to apply a constraint marked as 'only once' more than once: {ConstraintName}.`)
            end
        end

        local NextIndex = #ActiveConstraints + 1
        ActiveConstraints[NextIndex] = {Constraint, Args, HasFunctions, false, ConstraintName}
        self._LastConstraint = NextIndex
        return self
    end

    --- Adds a tag (for internal purposes)
    function TemplateClass:_AddTag(TagName)
        ExpectType(TagName, EXPECT_STRING, 1)

        if (self._Tags[TagName]) then
            error(`Tag already exists: {TagName}.`)
        end

        self = self:Copy()
        self._Tags[TagName] = true
        return self
    end

    function TemplateClass:_CreateCache()
        local Cache = setmetatable({}, WEAK_KEY_MT); -- Weak keys because we don't want to leak Instances or tables
        self._Cache = Cache
        return Cache
    end

    --- Checks if the value is of the correct type
    function TemplateClass:_Check(Value)
        local Tags = self._Tags
        local CacheTag = Tags.Cached
        local Cache

        if (CacheTag) then
            Cache = self._Cache or self:_CreateCache()

            local CacheValue = Cache[Value or NegativeCacheValue]

            if (CacheValue) then
                return CacheValue[1], CacheValue[2]
            end
        end

        -- Handle "type x or type y or type z ..."
        -- We do this before checking constraints to check if any of the other conditions succeed
        local Disjunctions = self._Disjunction

        for _, AlternateType in Disjunctions do
            if (type(AlternateType) == "function") then
                AlternateType = AlternateType(self)
            end

            local Success = AlternateType:_Check(Value)

            if (Success) then
                if (CacheTag) then
                    Cache[Value or NegativeCacheValue] = {true}
                end

                return true
            end
        end

        -- Handle "type x and type y and type z ..." - this is only really useful for objects and arrays
        for _, Conjunction in self._Conjunction do
            local Success, Message = Conjunction:_Check(Value)

            if (not Success) then
                local FailMessage = self._FailMessage
                local Result =
                    (type(FailMessage) == "function" and FailMessage(Value, RootContext) or FailMessage) or
                    (`[Conjunction {Conjunction}] {Message}`)

                if (CacheTag) then
                    Cache[Value or NegativeCacheValue] = {false, Result}
                end

                return false, Result
            end
        end

        -- Optional allows the value to be nil, in which case it won't be checked and we can resolve
        if (Tags.Optional and Value == nil) then
            if (CacheTag) then
                Cache[Value or NegativeCacheValue] = {true}
            end

            return true
        end

        -- Handle initial type check
        local Success, Message = self._Initial(Value)

        if (not Success) then
            if (Disjunctions[1]) then
                local Result = self._FailMessage or (`Disjunctions failed on {self}`)

                if (CacheTag) then
                    Cache[Value or NegativeCacheValue] = {false, Result}
                end

                return false, Result
            else
                Message = self._FailMessage or Message

                if (CacheTag) then
                    Cache[Value or NegativeCacheValue] = {false, Message}
                end

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
                    if (type(Arg) == "function") then
                        Args[Index] = Arg(RootContext)
                    end
                end
            end

            -- Call the constraint to verify it is satisfied
            local SubSuccess, SubMessage = Call(self, Value, unpack(Args))

            if (ShouldNegate) then
                SubMessage = if (SubSuccess) then
                                `Constraint '{ConstraintName}' succeeded but was expected to fail on value {Value}`
                                else
                                ""

                SubSuccess = not SubSuccess
            end

            if (not SubSuccess) then
                if (Disjunctions[1]) then
                    local Result = self._FailMessage or (`Disjunctions failed on {self}`)

                    if (CacheTag) then
                        Cache[Value or NegativeCacheValue] = {false, Result}
                    end

                    return false, Result
                end

                SubMessage = self._FailMessage or SubMessage

                if (CacheTag) then
                    Cache[Value or NegativeCacheValue] = {false, SubMessage}
                end

                return false, SubMessage
            end
        end

        if (CacheTag) then
            Cache[Value or NegativeCacheValue] = {true}
        end

        return true
    end

    --- Calling this will only check the type of the passed value if that value is not nil, i.e. it's an optional value so nothing can be passed, but if it is not nothing then it will be checked
    function TemplateClass:Optional()
        return self:_AddTag("Optional")
    end
    TemplateClass.optional = TemplateClass.Optional

    --- Enqueues a new constraint to satisfy 'or' i.e. "check x or check y or check z or ..." must pass
    function TemplateClass:Or(OtherType)
        if (type(OtherType) ~= "function") then
            TypeGuard._AssertIsTypeBase(OtherType, 1)
        end

        self = self:Copy()
        table.insert(self._Disjunction, OtherType)
        return self
    end
    TemplateClass.alternate = TemplateClass.Or

    --- Enqueues a new constraint to satisfy 'and' i.e. "check x and check y and check z and ..." must pass
    function TemplateClass:And(OtherType)
        TypeGuard._AssertIsTypeBase(OtherType, 1)

        self = self:Copy()
        table.insert(self._Conjunction, OtherType)
        return self
    end
    TemplateClass.additional = TemplateClass.And

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
    TemplateClass.AsPredicate = TemplateClass.WrapCheck
    TemplateClass.asPredicate = TemplateClass.WrapCheck

    --- Wraps Assert into its own callable function
    function TemplateClass:WrapAssert()
        return function(Value)
            return self:Assert(Value)
        end
    end
    TemplateClass.wrapAssert = TemplateClass.WrapAssert
    TemplateClass.AsAssertion = TemplateClass.WrapAssert
    TemplateClass.asAssertion = TemplateClass.WrapAssert

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
        local Alias = self._Alias

        if (Alias) then
            return Alias
        end

        local Fields = {}

        -- Constraints list (including arg, possibly other type defs)
        local ActiveConstraints = self._ActiveConstraints

        if (next(ActiveConstraints) ~= nil) then
            local InnerConstraints = {}

            for _, Constraint in ActiveConstraints do
                table.insert(InnerConstraints, Constraint[5] .. "(" .. ConcatWithToString(Constraint[2], ", ") .. ")")
            end

            table.insert(Fields, "Constraints = {" .. ConcatWithToString(InnerConstraints, ", ") .. "}")
        end

        -- Alternatives field str
        local Disjunction = self._Disjunction

        if (#Disjunction > 0) then
            local Alternatives = {}

            for _, AlternateType in Disjunction do
                table.insert(Alternatives, tostring(AlternateType))
            end

            table.insert(Fields, "Or = {" .. ConcatWithToString(Alternatives, ", ") .. "}")
        end

        -- Union fields str
        local Conjunction = self._Conjunction

        if (#Conjunction > 0) then
            local Unions = {}

            for _, Union in Conjunction do
                table.insert(Unions, tostring(Union))
            end

            table.insert(Fields, "And = {" .. ConcatWithToString(Unions, ", ") .. "}")
        end

        -- Tags (e.g. Optional, Strict)
        local Tags = self._Tags

        if (next(Tags) ~= nil) then
            local ResultTags = {}

            for Tag in Tags do
                table.insert(ResultTags, Tag)
            end

            table.insert(Fields, "Tags = {" .. ConcatWithToString(ResultTags, ", ") .. "}")
        end

        local Context = self._Context

        if (Context) then
            table.insert(Fields, "Context = " .. tostring(Context))
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
    assert(Subject.IsTemplate, "Subject is not a type template.")
end

--- Cheap & easy way to create a type without any constraints, and just an initial check corresponding to Roblox's typeof
function TypeGuard.FromTypeSample<T>(TypeName: string, Sample: T)
    ExpectType(TypeName, EXPECT_STRING, 1)

    local CheckerFunction, CheckerClass = TypeGuard.Template(TypeName)
    CheckerClass._Initial = CreateStandardInitial(TypeName)
    CheckerClass.InitialConstraint = CheckerClass.Equals

    type CustomTypeChecker = TypeChecker<CustomTypeChecker, T>
    return CheckerFunction :: TypeCheckerConstructor<CustomTypeChecker>
end
TypeGuard.fromTypeSample = TypeGuard.FromTypeSample




do
    type NumberTypeChecker = TypeChecker<NumberTypeChecker, number> & {
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

    local Number: TypeCheckerConstructor<NumberTypeChecker, number?, number?>, NumberClass = TypeGuard.Template("Number")
    NumberClass._Initial = CreateStandardInitial("number")

    --- Checks if the value is whole
    function NumberClass:Integer()
        return self:_AddConstraint(true, "Integer", function(_, Item)
            if (Item % 1 == 0) then
                return true
            end

            return false, `Expected integer form, got {Item}`
        end)
    end
    NumberClass.integer = NumberClass.Integer

    --- Checks if the number is a decimal
    function NumberClass:Decimal()
        return self:_AddConstraint(true, "Decimal", function(_, Item)
            if (Item % 1 ~= 0) then
                return true
            end

            return false, `Expected decimal form, got {Item}`
        end)
    end
    NumberClass.decimal = NumberClass.Decimal

    --- Ensures a number is between or equal to a minimum and maximum value. Can also function as "equals" - useful for this being used as the InitialConstraint.
    function NumberClass:RangeInclusive(Min, Max)
        ExpectType(Min, EXPECT_NUMBER_OR_FUNCTION, 1)
        Max = (Max == nil and Min or Max)
        ExpectType(Max, EXPECT_NUMBER_OR_FUNCTION, 2)

        if (Max == Min) then
            return self:Equals(Min)
        end

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
                return false, `Expected positive number, got {Item}`
            end

            return true
        end)
    end
    NumberClass.positive = NumberClass.Positive

    --- Checks the number is negative
    function NumberClass:Negative()
        return self:_AddConstraint(true, "Negative", function(_, Item)
            if (Item >= 0) then
                return false, `Expected negative number, got {Item}`
            end

            return true
        end)
    end
    NumberClass.negative = NumberClass.Negative

    --- Checks if the number is NaN
    function NumberClass:IsNaN()
        return self:_AddConstraint(true, "IsNaN", function(_, Item)
            if (Item ~= Item) then
                return true
            end

            return false, `Expected NaN, got {Item}`
        end)
    end
    NumberClass.isNaN = NumberClass.IsNaN

    --- Checks if the number is infinite
    function NumberClass:IsInfinite()
        return self:_AddConstraint(true, "IsInfinite", function(_, Item)
            if (Item == math.huge or Item == -math.huge) then
                return true
            end

            return false, `Expected infinite, got {Item}`
        end)
    end
    NumberClass.isInfinite = NumberClass.IsInfinite

    --- Checks if the number is close to another
    function NumberClass:IsClose(CloseTo, Tolerance)
        ExpectType(CloseTo, EXPECT_NUMBER_OR_FUNCTION, 1)
        Tolerance = Tolerance or 0.00001

        return self:_AddConstraint(true, "IsClose", function(_, NumberValue, CloseTo, Tolerance)
            if (math.abs(NumberValue - CloseTo) < Tolerance) then
                return true
            end

            return false, `Expected {CloseTo} +/- {Tolerance}, got {NumberValue}`
        end, CloseTo, Tolerance)
    end
    NumberClass.isClose = NumberClass.IsClose

    NumberClass.InitialConstraint = NumberClass.RangeInclusive

    TypeGuard.Number = Number
    TypeGuard.number = Number
end




do
    type StringTypeChecker = TypeChecker<StringTypeChecker, string> & {
        MinLength: SelfReturn<StringTypeChecker, number | (any?) -> number>;
        minLength: SelfReturn<StringTypeChecker, number | (any?) -> number>;

        MaxLength: SelfReturn<StringTypeChecker, number | (any?) -> number>;
        maxLength: SelfReturn<StringTypeChecker, number | (any?) -> number>;

        Pattern: SelfReturn<StringTypeChecker, string | (any?) -> string>;
        pattern: SelfReturn<StringTypeChecker, string | (any?) -> string>;

        Contains: SelfReturn<StringTypeChecker, string | (any?) -> string>;
        contains: SelfReturn<StringTypeChecker, string | (any?) -> string>;
    };

    local String: TypeCheckerConstructor<StringTypeChecker, string?>, StringClass = TypeGuard.Template("String")
    StringClass._Initial = CreateStandardInitial("string")

    --- Ensures a string is at least a certain length
    function StringClass:MinLength(MinLength)
        ExpectType(MinLength, EXPECT_NUMBER_OR_FUNCTION, 1)

        return self:_AddConstraint(true, "MinLength", function(_, Item, MinLength)
            if (#Item < MinLength) then
                return false, `Length must be at least {MinLength}, got {#Item}`
            end

            return true
        end, MinLength)
    end
    StringClass.minLength = StringClass.MinLength

    --- Ensures a string is at most a certain length
    function StringClass:MaxLength(MaxLength)
        ExpectType(MaxLength, EXPECT_NUMBER_OR_FUNCTION, 1)

        return self:_AddConstraint(true, "MaxLength", function(_, Item, MaxLength)
            if (#Item > MaxLength) then
                return false, `Length must be at most {MaxLength}, got {#Item}`
            end

            return true
        end, MaxLength)
    end
    StringClass.maxLength = StringClass.MaxLength

    --- Ensures a string matches a pattern
    function StringClass:Pattern(PatternString)
        ExpectType(PatternString, EXPECT_STRING_OR_FUNCTION, 1)

        return self:_AddConstraint(false, "Pattern", function(_, Item, Pattern)
            if (string.match(Item, Pattern) ~= Item) then
                return false, `String does not match pattern {Pattern}`
            end

            return true
        end, PatternString)
    end
    StringClass.pattern = StringClass.Pattern

    --- Ensures a string contains a certain substring
    function StringClass:Contains(SubstringValue)
        ExpectType(SubstringValue, EXPECT_STRING_OR_FUNCTION, 1)

        return self:_AddConstraint(false, "Contains", function(_, Item, Substring)
            if (string.find(Item, Substring) == nil) then
                return false, `String does not contain substring {Substring}`
            end

            return true
        end, SubstringValue)
    end

    StringClass.InitialConstraint = StringClass.Equals

    TypeGuard.String = String
    TypeGuard.string = String
end




do
    local PREFIX_ARRAY = "Index "
    local PREFIX_PARAM = "Param #"
    local ERR_PREFIX = "[%s%d] "
    local ERR_UNEXPECTED_VALUE = ERR_PREFIX .. " Unexpected value (strict tag is present)"

    type ArrayTypeChecker = TypeChecker<ArrayTypeChecker, {any}> & {
        OfLength: SelfReturn<ArrayTypeChecker, number | (any?) -> number>;
        ofLength: SelfReturn<ArrayTypeChecker, number | (any?) -> number>;

        MinLength: SelfReturn<ArrayTypeChecker, number | (any?) -> number>;
        minLength: SelfReturn<ArrayTypeChecker, number | (any?) -> number>;

        MaxLength: SelfReturn<ArrayTypeChecker, number | (any?) -> number>;
        maxLength: SelfReturn<ArrayTypeChecker, number | (any?) -> number>;

        Contains: SelfReturn<ArrayTypeChecker, any>;
        contains: SelfReturn<ArrayTypeChecker, any>;

        OfType: SelfReturn<ArrayTypeChecker, SignatureTypeChecker>;
        ofType: SelfReturn<ArrayTypeChecker, SignatureTypeChecker>;

        OfStructure: SelfReturn<ArrayTypeChecker, {SignatureTypeChecker}>;
        ofStructure: SelfReturn<ArrayTypeChecker, {SignatureTypeChecker}>;

        OfStructureStrict: SelfReturn<ArrayTypeChecker, {SignatureTypeChecker}>;
        ofStructureStrict: SelfReturn<ArrayTypeChecker, {SignatureTypeChecker}>;

        Strict: SelfReturn<ArrayTypeChecker>;
        strict: SelfReturn<ArrayTypeChecker>;

        DenoteParams: SelfReturn<ArrayTypeChecker>;
        denoteParams: SelfReturn<ArrayTypeChecker>;

        IsFrozen: SelfReturn<ArrayTypeChecker>;
        isFrozen: SelfReturn<ArrayTypeChecker>;

        IsOrdered: SelfReturn<ArrayTypeChecker, boolean | (any?) -> boolean>;
        isOrdered: SelfReturn<ArrayTypeChecker, boolean | (any?) -> boolean>;
    };

    local Array: TypeCheckerConstructor<ArrayTypeChecker, SignatureTypeChecker?>, ArrayClass = TypeGuard.Template("Array")

    function ArrayClass:_PrefixError(ErrorString: string, Index: number)
        return ErrorString:format((self._Tags.DenoteParams and PREFIX_PARAM or PREFIX_ARRAY), Index)
    end

    function ArrayClass._Initial(TargetArray)
        if (type(TargetArray) == "table") then
            -- This is fully reliable but uncomfortably slow, and therefore disabled for the meanwhile
            --[[ for Key in TargetArray do
                local KeyType = typeof(Key)

                if (KeyType ~= "number") then
                    return false, "Non-numeric key detected: " .. KeyType
                end
            end ]]

            -- This will catch the majority of cases
            local FirstKey = next(TargetArray)

            if (FirstKey == nil or FirstKey == 1) then
                return true
            end

            return false, "Array is empty"
        end

        return false, `Expected table, got {type(TargetArray)}`
    end

    --- Ensures an array is of a certain length
    function ArrayClass:OfLength(Length)
        ExpectType(Length, EXPECT_NUMBER_OR_FUNCTION, 1)

        return self:_AddConstraint(true, "Length", function(_, TargetArray, Length)
            if (#TargetArray ~= Length) then
                return false, `Length must be {Length}, got {#TargetArray}`
            end

            return true
        end, Length)
    end
    ArrayClass.ofLength = ArrayClass.OfLength

    --- Ensures an array is at least a certain length
    function ArrayClass:MinLength(MinLength)
        ExpectType(MinLength, EXPECT_NUMBER_OR_FUNCTION, 1)

        return self:_AddConstraint(true, "MinLength", function(_, TargetArray, MinLength)
            if (#TargetArray < MinLength) then
                return false, `Length must be at least {MinLength}, got {#TargetArray}`
            end

            return true
        end, MinLength)
    end
    ArrayClass.minLength = ArrayClass.MinLength

    --- Ensures an array is at most a certain length
    function ArrayClass:MaxLength(MaxLength)
        ExpectType(MaxLength, EXPECT_NUMBER_OR_FUNCTION, 1)

        return self:_AddConstraint(true, "MaxLength", function(_, TargetArray, MaxLength)
            if (#TargetArray > MaxLength) then
                return false, `Length must be at most {MaxLength}, got {#TargetArray}`
            end

            return true
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
                return false, `Value not found in array: {Value}`
            end

            return true
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

            return true
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

            return true
        end, SubTypesCopy, SubTypesAtPositions)
    end
    ArrayClass.ofStructure = ArrayClass.OfStructure

    --- OfStructure but strict
    function ArrayClass:OfStructureStrict(Other)
        return self:OfStructure(Other):Strict()
    end
    ArrayClass.ofStructureStrict = ArrayClass.OfStructureStrict

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
                return true
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
                return true
            end

            local Last = TargetArray[1]

            for Index = 2, Size do
                local Current = TargetArray[Index]

                if (Descending and Last < Current) then
                    return false, `Array is not ordered descending at index {Index}`
                elseif (Ascending and Last > Current) then
                    return false, `Array is not ordered ascending at index {Index}`
                end

                Last = Current
            end

            return true
        end, Descending)
    end
    ArrayClass.isOrdered = ArrayClass.IsOrdered

    ArrayClass.InitialConstraint = ArrayClass.OfType

    TypeGuard.Array = Array
end




do
    type TableTypeChecker = TypeChecker<TableTypeChecker, {any}> & {};

    local Table: TypeCheckerConstructor<TableTypeChecker, SignatureTypeChecker?>, TableClass = TypeGuard.Template("table")
    TableClass._Initial = TypeGuard.Template("table")

    TypeGuard.Table = Table
end




do
    type ObjectTypeChecker = TypeChecker<ObjectTypeChecker, {[any]: any}> & {
        OfStructure: SelfReturn<ObjectTypeChecker, {[any]: SignatureTypeChecker}>;
        ofStructure: SelfReturn<ObjectTypeChecker, {[any]: SignatureTypeChecker}>;

        OfStructureStrict: SelfReturn<ObjectTypeChecker, {[any]: SignatureTypeChecker}>;
        ofStructureStrict: SelfReturn<ObjectTypeChecker, {[any]: SignatureTypeChecker}>;

        Strict: SelfReturn<ObjectTypeChecker>;
        strict: SelfReturn<ObjectTypeChecker>;

        OfValueType: SelfReturn<ObjectTypeChecker, SignatureTypeChecker>;
        ofValueType: SelfReturn<ObjectTypeChecker, SignatureTypeChecker>;

        OfKeyType: SelfReturn<ObjectTypeChecker, SignatureTypeChecker>;
        ofKeyType: SelfReturn<ObjectTypeChecker, SignatureTypeChecker>;

        IsFrozen: SelfReturn<ObjectTypeChecker>;
        isFrozen: SelfReturn<ObjectTypeChecker>;

        CheckMetatable: SelfReturn<ObjectTypeChecker, SignatureTypeChecker>;
        checkMetatable: SelfReturn<ObjectTypeChecker, SignatureTypeChecker>;

        OfClass: SelfReturn<ObjectTypeChecker, any>;
        ofClass: SelfReturn<ObjectTypeChecker, any>;
    };

    local Object: TypeCheckerConstructor<ObjectTypeChecker, {[any]: SignatureTypeChecker}?>, ObjectClass = TypeGuard.Template("Object")

    function ObjectClass._Initial(TargetObject)
        if (type(TargetObject) == "table") then
            -- This is fully reliable but uncomfortably slow, and therefore disabled for the meanwhile
            --[[ for Key in TargetObject do
                if (typeof(Key) == "number") then
                    return false, "Incorrect key type: number"
                end
            end ]]

            -- This will catch the majority of cases
            if (rawget(TargetObject, 1) == nil) then
                return true
            end

            return false, "Incorrect key type: numeric index [1]"
        end

        return false, `Expected table, got {type(TargetObject)}`
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
                    return false, `[Key '{Key}'] is nil`
                end

                local Success, SubMessage = Checker:_Check(RespectiveValue)

                if (not Success) then
                    return false, `[Key '{Key}'] {SubMessage}`
                end
            end

            -- Check there are no extra fields which shouldn't be in the object
            if (SelfRef._Tags.Strict) then
                for Key in StructureCopy do
                    if (not SubTypes[Key]) then
                        return false, `[Key '{Key}'] unexpected (strict)`
                    end
                end
            end

            return true
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
                    return false, `[OfValueType: Key '{Index}'] {SubMessage}`
                end
            end

            return true
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
                    return false, `[OfKeyType: Key '{Key}'] {SubMessage}`
                end
            end

            return true
        end, SubType)
    end
    ObjectClass.ofKeyType = ObjectClass.OfKeyType

    --- Strict i.e. no extra key-value pairs than what is explicitly specified when using OfStructure
    function ObjectClass:Strict()
        return self:_AddTag("Strict")
    end
    ObjectClass.strict = ObjectClass.Strict

    --- Ensures no additional key-value pairs exist in the object other than what's verified here
    function ObjectClass:OfStructureStrict(Structure)
        return self:OfStructure(Structure):Strict()
    end
    ObjectClass.ofStructureStrict = ObjectClass.OfStructureStrict

    --- Checks if an object is frozen
    function ObjectClass:IsFrozen()
        return self:_AddConstraint(true, "IsFrozen", function(_, TargetObject)
            if (table.isfrozen(TargetObject)) then
                return true
            end

            return false, "Table was not frozen"
        end)
    end
    ObjectClass.isFrozen = ObjectClass.IsFrozen

    --- Checks an object's metatable
    function ObjectClass:CheckMetatable(Checker)
        TypeGuard._AssertIsTypeBase(Checker, 1)

        return self:_AddConstraint(true, "CheckMetatable", function(_, TargetObject, Checker)
            local Success, Message = Checker:_Check(getmetatable(TargetObject))

            if (Success) then
                return true
            end

            return false, `[Metatable] {Message}`
        end, Checker)
    end
    ObjectClass.checkMetatable = ObjectClass.CheckMetatable

    --- Checks if an object's __index points to the specified class
    function ObjectClass:OfClass(Class)
        ExpectType(Class, EXPECT_TABLE, 1)
        assert(Class.__index, "Class must have an __index")

        return self:CheckMetatable(Object():Equals(Class))
    end

    ObjectClass.InitialConstraint = ObjectClass.OfStructure

    TypeGuard.Object = Object
end




do
    type InstanceTypeChecker = TypeChecker<InstanceTypeChecker, Instance> & {
        OfStructure: SelfReturn<InstanceTypeChecker, {[string]: SignatureTypeChecker}>;
        ofStructure: SelfReturn<InstanceTypeChecker, {[string]: SignatureTypeChecker}>;

        OfStructureStrict: SelfReturn<InstanceTypeChecker, {[string]: SignatureTypeChecker}>;
        ofStructureStrict: SelfReturn<InstanceTypeChecker, {[string]: SignatureTypeChecker}>;

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

        CheckAttribute: SelfReturn<InstanceTypeChecker, string | (any?) -> string, SignatureTypeChecker>;
        checkAttribute: SelfReturn<InstanceTypeChecker, string | (any?) -> string, SignatureTypeChecker>;

        HasTags: SelfReturn<InstanceTypeChecker, {string} | (any?) -> {string}>;
        hasTags: SelfReturn<InstanceTypeChecker, {string} | (any?) -> {string}>;

        HasAttributes: SelfReturn<InstanceTypeChecker, {string} | (any?) -> {string}>;
        hasAttributes: SelfReturn<InstanceTypeChecker, {string} | (any?) -> {string}>;

        CheckAttributes: SelfReturn<InstanceTypeChecker, {[string]: SignatureTypeChecker} | (any?) -> {[string]: SignatureTypeChecker}>;
        checkAttributes: SelfReturn<InstanceTypeChecker, {[string]: SignatureTypeChecker} | (any?) -> {[string]: SignatureTypeChecker}>;
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

    local InstanceChecker: TypeCheckerConstructor<InstanceTypeChecker, string? | ((any?) -> string)?, {[string]: SignatureTypeChecker}?>, InstanceCheckerClass = TypeGuard.Template("Instance")
    InstanceCheckerClass._Initial = CreateStandardInitial("Instance")

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
                    return false, `{(typeof(Value) == "Instance" and "[Instance '" or "[Property '")}{Key}'] {SubMessage}`
                end
            end

            -- Check there are no extra children which shouldn't be in the Instance
            if (SelfRef._Tags.Strict) then
                for _, Value in InstanceRoot:GetChildren() do
                    local Key = Value.Name
                    local Checker = SubTypes[Key]

                    if (not Checker) then
                        return false, `[Instance '{Key}'] unexpected (strict)`
                    end
                end
            end

            return true
        end, SubTypesCopy)
    end
    InstanceCheckerClass.ofStructure = InstanceCheckerClass.OfStructur

    --- Uses Instance.IsA to assert the type of an Instance
    function InstanceCheckerClass:IsA(InstanceIsA)
        ExpectType(InstanceIsA, EXPECT_STRING_OR_FUNCTION, 1)

        return self:_AddConstraint(true, "IsA", function(_, InstanceRoot, InstanceIsA)
            if (not InstanceRoot:IsA(InstanceIsA)) then
                return false, `Expected {InstanceIsA}, got {InstanceRoot.ClassName}`
            end

            return true
        end, InstanceIsA)
    end
    InstanceCheckerClass.isA = InstanceCheckerClass.IsA

    --- Activates strict tag for OfStructure
    function InstanceCheckerClass:Strict()
        return self:_AddTag("Strict")
    end
    InstanceCheckerClass.strict = InstanceCheckerClass.Strict

    --- OfStructure + strict tag i.e. no extra children exist beyond what is specified
    function InstanceCheckerClass:OfStructureStrict(Structure)
        return self:OfStructure(Structure):Strict()
    end
    InstanceCheckerClass.ofStructureStrict = InstanceCheckerClass.OfStructureStrict

    --- Checks if an Instance has a particular tag
    function InstanceCheckerClass:HasTag(Tag: string)
        ExpectType(Tag, EXPECT_STRING_OR_FUNCTION, 1)

        return self:_AddConstraint(false, "HasTag", function(_, InstanceRoot, Tag)
            if (CollectionService:HasTag(InstanceRoot, Tag)) then
                return true
            end

            return false, `Expected tag '{Tag}' on Instance {InstanceRoot:GetFullName()}`
        end, Tag)
    end
    InstanceCheckerClass.hasTag = InstanceCheckerClass.HasTag

    --- Checks if an Instance has a particular attribute
    function InstanceCheckerClass:HasAttribute(Attribute: string)
        ExpectType(Attribute, EXPECT_STRING_OR_FUNCTION, 1)

        return self:_AddConstraint(false, "HasAttribute", function(_, InstanceRoot, Attribute)
            if (InstanceRoot:GetAttribute(Attribute) ~= nil) then
                return true
            end

            return false, `Expected attribute '{Attribute}' to exist on Instance {InstanceRoot:GetFullName()}`
        end, Attribute)
    end
    InstanceCheckerClass.hasAttribute = InstanceCheckerClass.HasAttribute

    --- Applies a TypeChecker to an Instance's expected attribute
    function InstanceCheckerClass:CheckAttribute(Attribute: string, Checker: SignatureTypeChecker)
        ExpectType(Attribute, EXPECT_STRING_OR_FUNCTION, 1)
        TypeGuard._AssertIsTypeBase(Checker, 2)

        return self:_AddConstraint(false, "CheckAttribute", function(_, InstanceRoot, Attribute)
            local Success, SubMessage = (Checker :: SignatureTypeCheckerInternal):_Check(InstanceRoot:GetAttribute(Attribute))

            if (not Success) then
                return false, `Attribute '{Attribute}' not satisfied on Instance {InstanceRoot:GetFullName()}: {SubMessage}`
            end

            return true
        end, Attribute, Checker)
    end
    InstanceCheckerClass.checkAttribute = InstanceCheckerClass.CheckAttribute

    --- Checks if an Instance has a set of tags
    function InstanceCheckerClass:HasTags(Tags: {string})
        ExpectType(Tags, EXPECT_TABLE_OR_FUNCTION, 1)

        if (type(Tags) == "table") then
            for Index, Tag in Tags do
                assert(type(Tag) == "string", `Expected tag #{Index} to be a string`)
            end
        end

        return self:_AddConstraint(false, "HasTags", function(_, InstanceRoot, Tags)
            for _, Tag in Tags do
                if (not CollectionService:HasTag(InstanceRoot, Tag)) then
                    return false, `Expected tag '{Tag}' on Instance {InstanceRoot:GetFullName()}`
                end
            end

            return true
        end, Tags)
    end
    InstanceCheckerClass.hasTags = InstanceCheckerClass.HasTags

    --- Checks if an Instance has a set of attributes
    function InstanceCheckerClass:HasAttributes(Attributes: {string})
        ExpectType(Attributes, EXPECT_TABLE_OR_FUNCTION, 1)

        if (type(Attributes) == "table") then
            for Index, Attribute in Attributes do
                assert(type(Attribute) == "string", `Expected attribute #{Index} to be a string`)
            end
        end

        return self:_AddConstraint(false, "HasAttributes", function(_, InstanceRoot, Attributes)
            for _, Attribute in Attributes do
                if (InstanceRoot:GetAttribute(Attribute) == nil) then
                    return false, `Expected attribute '{Attribute}' to exist on Instance {InstanceRoot:GetFullName()}`
                end
            end

            return true
        end, Attributes)
    end
    InstanceCheckerClass.hasAttributes = InstanceCheckerClass.HasAttributes

    --- Applies a TypeChecker to an Instance's expected attribute
    function InstanceCheckerClass:CheckAttributes(AttributeCheckers: {SignatureTypeChecker})
        ExpectType(AttributeCheckers, EXPECT_TABLE, 1)

        for Attribute, Checker in AttributeCheckers do
            assert(type(Attribute) == "string", `Attribute '{Attribute}' was not a string`)
            TypeGuard._AssertIsTypeBase(Checker, "")
        end

        return self:_AddConstraint(false, "CheckAttributes", function(_, InstanceRoot, AttributeCheckers)
            for Attribute, Checker in AttributeCheckers do
                local Success, SubMessage = Checker:_Check(InstanceRoot:GetAttribute(Attribute))

                if (not Success) then
                    return false, `Attribute '{Attribute}' not satisfied on Instance "{InstanceRoot:GetFullName()}: {SubMessage}`
                end
            end

            return true
        end, AttributeCheckers)
    end
    InstanceCheckerClass.checkAttributes = InstanceCheckerClass.CheckAttributes

    --- Checks if an Instance is a descendant of a particular Instance
    function InstanceCheckerClass:IsDescendantOf(Instance)
        ExpectType(Instance, EXPECT_INSTANCE_OR_FUNCTION, 1)

        return self:_AddConstraint(true, "IsDescendantOf", function(_, SubjectInstance, Instance)
            if (SubjectInstance:IsDescendantOf(Instance)) then
                return true
            end

            return false, `Expected Instance {SubjectInstance:GetFullName()} to be a descendant of {Instance:GetFullName()}`
        end, Instance)
    end
    InstanceCheckerClass.isDescendantOf = InstanceCheckerClass.IsDescendantOf

    --- Checks if an Instance is an ancestor of a particular Instance
    function InstanceCheckerClass:IsAncestorOf(Instance)
        ExpectType(Instance, EXPECT_INSTANCE_OR_FUNCTION, 1)

        return self:_AddConstraint(false, "IsAncestorOf", function(_, SubjectInstance, Instance)
            if (SubjectInstance:IsAncestorOf(Instance)) then
                return true
            end

            return false, `Expected Instance {SubjectInstance:GetFullName()} to be an ancestor of {Instance:GetFullName()}`
        end, Instance)
    end
    InstanceCheckerClass.isAncestorOf = InstanceCheckerClass.IsAncestorOf

    --- Checks if a particular child exists in an Instance
    function InstanceCheckerClass:HasChild(Name)
        ExpectType(Name, EXPECT_STRING_OR_FUNCTION, 1)

        return self:_AddConstraint(false, "HasChild", function(_, InstanceRoot, Name)
            if (InstanceRoot:FindFirstChild(Name)) then
                return true
            end

            return false, `Expected child '{Name}' to exist on Instance {InstanceRoot:GetFullName()}`
        end, Name)
    end
    InstanceCheckerClass.hasChild = InstanceCheckerClass.HasChild

    InstanceCheckerClass.InitialConstraints = {InstanceCheckerClass.IsA, InstanceCheckerClass.OfStructure}

    TypeGuard.Instance = InstanceChecker
end




do
    type BooleanTypeChecker = TypeChecker<BooleanTypeChecker, boolean>;

    local Boolean: TypeCheckerConstructor<BooleanTypeChecker> & {}, BooleanClass = TypeGuard.Template("Boolean")
    BooleanClass._Initial = CreateStandardInitial("boolean")

    BooleanClass.InitialConstraint = BooleanClass.Equals

    TypeGuard.Boolean = Boolean
    TypeGuard.boolean = Boolean
end




do
    type EnumTypeChecker = TypeChecker<EnumTypeChecker, Enum | EnumItem> & {
        IsA: SelfReturn<EnumTypeChecker, Enum | EnumItem | (any?) -> Enum | EnumItem>;
        isA: SelfReturn<EnumTypeChecker, Enum | EnumItem | (any?) -> Enum | EnumItem>;
    };

    local EnumChecker: TypeCheckerConstructor<EnumTypeChecker, Enum? | EnumItem? | (any?) -> (Enum | EnumItem)?>, EnumCheckerClass = TypeGuard.Template("Enum")

    function EnumCheckerClass._Initial(Value)
        local GotType = typeof(Value)

        if (GotType == "EnumItem" or GotType == "Enum") then
            return true
        end

        return false, `Expected EnumItem or Enum, got {GotType}`
    end

    --- Ensures that a passed EnumItem is either equivalent to an EnumItem or a sub-item of an Enum class
    function EnumCheckerClass:IsA(TargetEnum)
        ExpectType(TargetEnum, EXPECT_ENUM_OR_ENUM_ITEM_OR_FUNCTION, 1)

        return self:_AddConstraint(true, "IsA", function(_, Value, TargetEnum)
            local TargetType = typeof(TargetEnum)

            -- Both are EnumItems
            if (TargetType == "EnumItem") then
                if (Value == TargetEnum) then
                    return true
                end

                return false, `Expected {TargetEnum}, got {Value}`
            end

            -- TargetType is an Enum
            if (table.find(TargetEnum:GetEnumItems(), Value) == nil) then
                return false, `Expected a {TargetEnum}, got {Value}`
            end

            return true
        end, TargetEnum)
    end
    EnumCheckerClass.isA = EnumCheckerClass.IsA

    EnumCheckerClass.InitialConstraint = EnumCheckerClass.IsA

    TypeGuard.Enum = EnumChecker
end




do
    type ThreadTypeChecker = TypeChecker<ThreadTypeChecker, thread> & {
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
    ThreadCheckerClass._Initial = CreateStandardInitial("thread")

    function ThreadCheckerClass:IsDead()
        return self:HasStatus("dead"):_AddTag("StatusCheck")
    end
    ThreadCheckerClass.isDead = ThreadCheckerClass.IsDead

    function ThreadCheckerClass:IsSuspended()
        return self:HasStatus("suspended"):_AddTag("StatusCheck")
    end
    ThreadCheckerClass.isSuspended = ThreadCheckerClass.IsSuspended

    function ThreadCheckerClass:IsRunning()
        return self:HasStatus("running"):_AddTag("StatusCheck")
    end
    ThreadCheckerClass.isRunning = ThreadCheckerClass.IsRunning

    function ThreadCheckerClass:IsNormal()
        return self:HasStatus("normal"):_AddTag("StatusCheck")
    end
    ThreadCheckerClass.isNormal = ThreadCheckerClass.IsNormal

    --- Checks the coroutine's status against a given status string
    function ThreadCheckerClass:HasStatus(Status)
        ExpectType(Status, EXPECT_STRING_OR_FUNCTION, 1)

        return self:_AddConstraint(true, "HasStatus", function(_, Thread, Status)
            local CurrentStatus = coroutine.status(Thread)

            if (CurrentStatus == Status) then
                return true
            end

            return false, `Expected thread to have status '{Status}', got {CurrentStatus}`
        end, Status)
    end

    TypeGuard.InitialConstraint = ThreadCheckerClass.HasStatus

    TypeGuard.Thread = ThreadChecker
    TypeGuard.thread = ThreadChecker
end




do
    type AnyTypeChecker = TypeChecker<AnyTypeChecker, any>

    local AnyChecker: TypeCheckerConstructor<AnyTypeChecker>, AnyCheckerClass = TypeGuard.Template("Any")

    function AnyCheckerClass._Initial(Item)
        if (Item == nil) then
            return false, "Expected something, got nil"
        end

        return true
    end

    TypeGuard.Any = AnyChecker
    TypeGuard.any = AnyChecker
end




-- Luau data types: these must be manually enumerated because the type checker will not process them fully for intellisense otherwise
local Any: any = {}
local Sample = TypeGuard.FromTypeSample

TypeGuard.Axes = Sample("Axes", Axes.new())
TypeGuard.BrickColor = Sample("BrickColor", BrickColor.Black())
TypeGuard.CatalogSearchParams = Sample("CatalogSearchParams", CatalogSearchParams.new())
TypeGuard.CFrame = Sample("CFrame", CFrame.new())
TypeGuard.Color3 = Sample("Color3", Color3.new())
TypeGuard.ColorSequence = Sample("ColorSequence", ColorSequence.new(Color3.new()))
TypeGuard.ColorSequenceKeypoint = Sample("ColorSequenceKeypoint", ColorSequenceKeypoint.new(0, Color3.new()))
TypeGuard.DateTime = Sample("DateTime", DateTime.now())
TypeGuard.DockWidgetPluginGuiInfo = Sample("DockWidgetPluginGuiInfo", DockWidgetPluginGuiInfo.new())
TypeGuard.Enums = Sample("Enums", Enum)
TypeGuard.Faces = Sample("Faces", Faces.new())
TypeGuard.FloatCurveKey = Sample("FloatCurveKey", Any)
TypeGuard.NumberRange = Sample("NumberRange", NumberRange.new(0, 0))
TypeGuard.NumberSequence = Sample("NumberSequence", NumberSequence.new(1))
TypeGuard.NumberSequenceKeypoint = Sample("NumberSequenceKeypoint", NumberSequenceKeypoint.new(1, 1))
TypeGuard.OverlapParams = Sample("OverlapParams", OverlapParams.new())
TypeGuard.PathWaypoint = Sample("PathWaypoint", PathWaypoint.new(Vector3.new(), Enum.PathWaypointAction.Jump))
TypeGuard.PhysicalProperties = Sample("PhysicalProperties", PhysicalProperties.new(Enum.Material.Air))
TypeGuard.Random = Sample("Random", Random.new())
TypeGuard.Ray = Sample("Ray", Ray.new(Vector3.new(), Vector3.new()))
TypeGuard.RaycastParams = Sample("RaycastParams", RaycastParams.new())
TypeGuard.RaycastResult = Sample("RaycastResult", Any)
TypeGuard.RBXScriptConnection = Sample("RBXScriptConnection", Instance.new("BindableEvent").Event:Connect(function() end))
TypeGuard.RBXScriptSignal = Sample("RBXScriptSignal", Instance.new("BindableEvent").Event)
TypeGuard.Rect = Sample("Rect", Rect.new(Vector2.new(), Vector2.new()))
TypeGuard.Region3 = Sample("Region3", Region3.new(Vector3.new(), Vector3.new()))
TypeGuard.Region3int16 = Sample("Region3int16", Region3int16.new(Vector3int16.new(), Vector3int16.new()))
TypeGuard.TweenInfo = Sample("TweenInfo", TweenInfo.new())
TypeGuard.UDim = Sample("UDim", UDim.new())
TypeGuard.UDim2 = Sample("UDim2", UDim2.new())
TypeGuard.Vector2 = Sample("Vector2", Vector2.new())
TypeGuard.Vector2int16 = Sample("Vector2int16", Vector2int16.new(0, 0))
TypeGuard.Vector3 = Sample("Vector3", Vector3.new())
TypeGuard.Vector3int16 = Sample("Vector3int16", Vector3int16.new())

-- Extra base Lua data types
TypeGuard.Function = TypeGuard.FromTypeSample("function", function() end)
TypeGuard.lfunction = TypeGuard.Function

TypeGuard.Userdata = TypeGuard.FromTypeSample("userdata", newproxy(true))
TypeGuard.luserdata = TypeGuard.Userdata

TypeGuard.Nil = TypeGuard.FromTypeSample("nil", nil)
TypeGuard.lnil = TypeGuard.Nil

do -- Misc functions
    local function _GetScript(): string
        local ScriptName = debug.info(3, "s")
        local Splits = string.split(ScriptName, ".")
        return Splits[#Splits] or ScriptName
    end

    local ValidTypeChecker = TypeGuard.Object({
        _Check = TypeGuard.Function();
    })

    --- Creates a function which checks params as if they were a strict Array checker
    function TypeGuard.Params(...: SignatureTypeChecker)
        local Args = {...}
        local ArgSize = #Args

        for Index, ParamChecker in Args do
            ValidTypeChecker:Assert(ParamChecker)
        end

        local Script = _GetScript()
        ScriptNameToContextEnabled[Script] = if (ScriptNameToContextEnabled[Script] ~= nil)
                                            then ScriptNameToContextEnabled[Script]
                                            else true

        return function(...)
            if (not ScriptNameToContextEnabled[Script]) then
                return
            end

            debug.profilebegin("TG.P")

            local Size = select("#", ...)

            if (Size > ArgSize) then
                error(`Expected {ArgSize} argument{(ArgSize == 1 and "" or "s")}, got {Size}.`)
            end

            for Index, Value in Args do
                local Arg = select(Index, ...)
                local Success, Message = Value:_Check(Arg)

                if (not Success) then
                    error(`Invalid argument #{Index} ({Message}).`)
                end
            end

            debug.profileend()
        end
    end
    TypeGuard.params = TypeGuard.Params

    local VariadicParams = TypeGuard.Params(ValidTypeChecker)
    --- Creates a function which checks variadic params against a single given TypeChecker
    function TypeGuard.Variadic(CompareType: SignatureTypeChecker)
        VariadicParams(CompareType)

        local Script = _GetScript()
        ScriptNameToContextEnabled[Script] = if (ScriptNameToContextEnabled[Script] ~= nil)
                                            then ScriptNameToContextEnabled[Script]
                                            else true

        return function(...)
            if (not ScriptNameToContextEnabled[Script]) then
                return
            end

            debug.profilebegin("TG.V")

            local Size = select("#", ...)

            for Index = 1, Size do
                local Arg = select(Index, ...)
                local Success, Message = (CompareType :: SignatureTypeCheckerInternal):_Check(Arg)

                if (not Success) then
                    error(`Invalid argument #{Index} ({Message}).`)
                end
            end

            debug.profileend()
        end
    end
    TypeGuard.variadic = TypeGuard.Variadic

    local ParamsWithContextParams = TypeGuard.Variadic(ValidTypeChecker)
    --- Creates a function which checks params as if they were a strict Array checker, using context as the first param; context is passed down to functional constraint args
    function TypeGuard.ParamsWithContext(...: SignatureTypeChecker)
        ParamsWithContextParams(...)

        local Args = {...}
        local ArgSize = #Args

        for Index, ParamChecker in Args do
            TypeGuard._AssertIsTypeBase(ParamChecker, Index)
        end

        local Script = _GetScript()
        ScriptNameToContextEnabled[Script] = if (ScriptNameToContextEnabled[Script] ~= nil)
                                            then ScriptNameToContextEnabled[Script]
                                            else true

        return function(Context: any?, ...)
            if (not ScriptNameToContextEnabled[Script]) then
                return
            end

            debug.profilebegin("TG.P+")

            local Size = select("#", ...)

            if (Size > ArgSize) then
                error(`Expected {ArgSize} argument{(ArgSize == 1 and "" or "s")}, got {Size}.`)
            end

            for Index, Value in Args do
                local Arg = select(Index, ...)
                local Success, Message = Value:WithContext(Context):Check(Arg)

                if (not Success) then
                    error(`Invalid argument #{Index} ({Message}).`)
                end
            end

            debug.profileend()
        end
    end
    TypeGuard.paramsWithContext = TypeGuard.ParamsWithContext

    local VariadicWithContextParams = TypeGuard.Params(ValidTypeChecker)
    --- Creates a function which checks variadic params against a single given TypeChecker, using context as the first param; context is passed down to functional constraint args
    function TypeGuard.VariadicWithContext(CompareType: SignatureTypeChecker)
        VariadicWithContextParams(CompareType)

        local Script = _GetScript()
        ScriptNameToContextEnabled[Script] = if (ScriptNameToContextEnabled[Script] ~= nil)
                                            then ScriptNameToContextEnabled[Script]
                                            else true

        return function(Context: any?, ...)
            if (not ScriptNameToContextEnabled[Script]) then
                return
            end

            debug.profilebegin("TG.V+")

            local Size = select("#", ...)

            for Index = 1, Size do
                local Arg = select(Index, ...)
                local Success, Message = (CompareType :: SignatureTypeCheckerInternal):WithContext(Context):Check(Arg)

                if (not Success) then
                    error(`Invalid argument #{Index} ({Message}).`)
                end
            end

            debug.profileend()
        end
    end
    TypeGuard.variadicWithContext = TypeGuard.VariadicWithContext

    local WrapFunctionParamsParams1 = TypeGuard.Params(TypeGuard.Function())
    local WrapFunctionParamsParams2 = TypeGuard.Variadic(ValidTypeChecker)
    --- Wraps a function in a param checker function
    function TypeGuard.WrapFunctionParams(Call: (...any) -> (...any), ...: SignatureTypeChecker)
        WrapFunctionParamsParams1(Call)
        WrapFunctionParamsParams2(...)

        for Index = 1, select("#", ...) do
            TypeGuard._AssertIsTypeBase(select(Index, ...), Index)
        end

        local ParamChecker = TypeGuard.Params(...)

        return function(...)
            ParamChecker(...)
            return Call(...)
        end
    end
    TypeGuard.wrapFunctionParams = TypeGuard.WrapFunctionParams

    local WrapFunctionVariadicParams = TypeGuard.Params(TypeGuard.Function(), ValidTypeChecker)
    --- Wraps a function in a variadic param checker function
    function TypeGuard.WrapFunctionVariadic(Call: (...any) -> (...any), VariadicParamType: SignatureTypeChecker)
        WrapFunctionVariadicParams(Call, VariadicParamType)

        local ParamChecker = TypeGuard.Variadic(VariadicParamType)

        return function(...)
            ParamChecker(...)
            return Call(...)
        end
    end
    TypeGuard.wrapFunctionVariadic = TypeGuard.WrapFunctionVariadic

    local Primitives = {
        ["nil"] = "Nil";
        ["string"] = "String";
        ["number"] = "Number";
        ["thread"] = "Thread";
        ["boolean"] = "Boolean";
        ["function"] = "Function";
        ["userdata"] = "Userdata";
    }

    local function _FromTemplate(Subject: any, Strict: boolean?)
        local Type = typeof(Subject)
        Type = Primitives[Type] or Type

        if (Type == "table") then
            if (Subject[1]) then
                local Last
                local LastType = ""

                for Key, Value in Subject do
                    local Temp = _FromTemplate(Value, Strict)

                    if (Temp.Type == LastType) then
                        continue
                    end

                    Last = if (Last) then Temp:Or(Last) else Temp
                    LastType = Temp.Type
                end

                return TypeGuard.Array(Strict and Last:Strict() or Last)
            else
                local Result = {}

                for Key, Value in Subject do
                    Result[Key] = _FromTemplate(Value, Strict)
                end

                local Temp = TypeGuard.Object(Result)
                return Strict and Temp:Strict() or Temp
            end
        end

        if (Type == "Instance") then
            local Structure = {}

            for _, Child in Subject:GetChildren() do
                Structure[Child.Name] = _FromTemplate(Child, Strict)
            end

            local Base = TypeGuard.Instance(Subject.ClassName)
            Base = Strict and Base:Strict() or Base
            return if (next(Structure)) then Base:OfStructure(Structure) else Base
        end

        if (Type == "EnumItem") then
            return TypeGuard.Enum(Subject)
        end

        local Constructor = TypeGuard[Type]

        if (not Constructor) then
            error("Unknown type: " .. Type)
        end

        return Constructor()
    end

    local FromTemplateParams = TypeGuard.Params(TypeGuard.Boolean():Optional())
    --- Creates a TypeChecker from a template table.
    function TypeGuard.FromTemplate(Subject: any, Strict: boolean?)
        FromTemplateParams(Strict)
        return _FromTemplate(Subject, Strict)
    end

    local SetContextEnabledParams = TypeGuard.Params(TypeGuard.String():IsAKeyIn(ScriptNameToContextEnabled), TypeGuard.Boolean())
    --- Certain scripts may want to disable type checking for a specific context for performance.
    function TypeGuard.SetContextEnabled(Name: string, Enabled: boolean)
        SetContextEnabledParams(Name, Enabled)
        ScriptNameToContextEnabled[Name] = Enabled
    end

    local SetCurrentContextEnabledParams = TypeGuard.Params(TypeGuard.Boolean())
    --- Sets the context for the calling script, which can be enabled or disabled with TypeGuard.SetContextEnabled.
    function TypeGuard.SetCurrentContextEnabled(Enabled: boolean)
        SetCurrentContextEnabledParams(Enabled)
        ScriptNameToContextEnabled[_GetScript()] = Enabled
    end
end

return TypeGuard