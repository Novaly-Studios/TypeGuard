export type AnyMethod = (...any) -> (...any)
export type SignatureTypeChecker = {
    _TC: true;
}
export type SignatureTypeCheckerInternal = SignatureTypeChecker & { -- Stops Luau from complaining in the main script.
    GreaterThanOrEqualTo: AnyMethod;
    LessThanOrEqualTo: AnyMethod;
    GreaterThan: AnyMethod;
    FailMessage: AnyMethod;
    AsPredicate: AnyMethod;
    WithContext: AnyMethod;
    IsAValueIn: AnyMethod;
    AsAssert: AnyMethod;
    IsAKeyIn: AnyMethod;
    LessThan: AnyMethod;
    Optional: AnyMethod;
    Equals: AnyMethod;
    Assert: AnyMethod;
    Check: AnyMethod;
    Cached: AnyMethod;
    Negate: AnyMethod;
    Alias: AnyMethod;
    Copy: AnyMethod;
    And: AnyMethod;
    Or: AnyMethod;

    _AddConstraint: AnyMethod;
    _CreateCache: AnyMethod;
    _AddTag: AnyMethod;
    _Check: AnyMethod;
}

export type SelfReturn<T, P...> = ((T, P...) -> T)
export type TypeCheckerConstructor<T, P...> = ((P...) -> T)

export type TypeChecker<ExtensionClass, Primitive> = {
    _TC: true;

    -- Methods available in all TypeCheckers.
    FailMessage: SelfReturn<ExtensionClass, string>;
    AsAssertion: (ExtensionClass) -> ((any?) -> ());
    AsPredicate: (ExtensionClass) -> ((any?) -> (boolean, string?));
    WithContext: SelfReturn<ExtensionClass, any?>;
    Optional: SelfReturn<ExtensionClass>;
    Assert: (ExtensionClass, any) -> ();
    Negate: SelfReturn<ExtensionClass>;
    Cached: SelfReturn<ExtensionClass>;
    Check: (ExtensionClass, any) -> (boolean, string?);
    Alias: SelfReturn<ExtensionClass, string>;
    Copy: SelfReturn<ExtensionClass>;
    And: SelfReturn<ExtensionClass, SignatureTypeChecker>;
    Or: SelfReturn<ExtensionClass, SignatureTypeChecker | () -> SignatureTypeChecker>;

    -- Constraints available in all TypeCheckers.
    GreaterThanOrEqualTo: SelfReturn<ExtensionClass, Primitive | ((any?) -> Primitive)>;
    LessThanOrEqualTo: SelfReturn<ExtensionClass, Primitive | ((any?) -> Primitive)>;
    GreaterThan: SelfReturn<ExtensionClass, Primitive | ((any?) -> Primitive)>;
    IsAValueIn: SelfReturn<ExtensionClass, any | ((any?) -> any)>;
    LessThan: SelfReturn<ExtensionClass, Primitive | ((any?) -> Primitive)>;
    IsAKeyIn: SelfReturn<ExtensionClass, any | ((any?) -> any)>;
    Equals: SelfReturn<ExtensionClass, any | ((any?) -> any)>;
};

local Util = require(script.Parent.Parent:WaitForChild("Util"))
    local ConcatWithToString = Util.ConcatWithToString
    local AssertIsTypeBase = Util.AssertIsTypeBase
    local ExpectType = Util.ExpectType
    local Expect = Util.Expect

-- Standard re-usable functions throughout all TypeCheckers.
local function IsAKeyIn(self, Store)
    ExpectType(Store, Expect.TABLE_OR_FUNCTION, 1)

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
    ExpectType(Store, Expect.TABLE_OR_FUNCTION, 1)

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

        return false, `Value {Value} is not greater than or equal to {GTEValue}`
    end, GTEValue)
end

local function LessThanOrEqualTo(self, LTEValue)
    return self:_AddConstraint(true, "LessThanOrEqualTo", function(_, Value, LTEValue)
        if (Value <= LTEValue) then
            return true
        end

        return false, `Value {Value} is not less than or equal to {LTEValue}`
    end, LTEValue)
end

local WEAK_KEY_MT = {__mode = "ks"}
local USE_INDEX = false

local NegativeCacheValue = {} -- Exists for Cached() because nil causes problems.
local RootContext = nil -- Faster & easier just using one high scope variable which all TypeCheckers can access during checking time, than propogating the context downwards.

--- Creates a template TypeChecker object that can be used to extend behaviors via constraints.
local function CreateTemplate(Name: string)
    ExpectType(Name, Expect.STRING, 1)

    local TemplateClass = {
        InitialConstraintsDirectVariadic = nil;
        InitialConstraintsVariadic = nil;
        InitialConstraints = nil;
        InitialConstraint = nil;
        Type = Name;
        _TC = true;
    }
    TemplateClass.__index = TemplateClass

    function TemplateClass.new(...)
        local self = {
            _Tags = {};
            _Disjunction = {};
            _Conjunction = {};
            _ActiveConstraints = {};

            --[[
                _Cache = nil;
                _Context = nil;
                _FailMessage = nil;
            ]]
            _LastConstraint = "";
        }

        -- __index slows down benchmarks by ~10%. We should safely be able to get away with copying in
        -- methods & data manually without causing large heap size increases.
        if (USE_INDEX) then
            setmetatable(self, TemplateClass)
        else
            for Key, Value in TemplateClass do
                if (Key == "new" or Key == "__index" or Key == "__tostring") then
                    continue
                end

                self[Key] = Value
            end

            setmetatable(self, {__tostring = TemplateClass.__tostring})
        end

        local NumArgs = select("#", ...)

        -- Support for a single constraint passed as the constructor, with an arbitrary number of args.
        local InitialConstraint = self.InitialConstraint

        if (InitialConstraint and NumArgs > 0) then
            return InitialConstraint(self, ...)
        end

        -- Multiple constraints support (but only ONE arg per constraint is supported currently).
        local InitialConstraints = TemplateClass.InitialConstraints

        if (InitialConstraints and NumArgs > 0) then
            for Index = 1, NumArgs do
                self = InitialConstraints[Index](self, select(Index, ...))
            end

            return self
        end

        -- Variadic constraints support.
        local InitialConstraintsVariadic = TemplateClass.InitialConstraintsVariadic

        if (InitialConstraintsVariadic and NumArgs > 0) then
            for Index = 1, NumArgs do
                self = InitialConstraintsVariadic(self, select(Index, ...))
            end

            return self
        end

        -- Direct variadic: pass all arguments to one constraint instead of copying this object each time.
        local InitialConstraintsDirectVariadic = TemplateClass.InitialConstraintsDirectVariadic

        if (InitialConstraintsDirectVariadic and NumArgs > 0) then
            return InitialConstraintsDirectVariadic(self, ...)
        end

        return self
    end

    --- Creates a copy of this TypeChecker.
    function TemplateClass:Copy()
        local New = TemplateClass.new()

        -- Copy tags...
        for Key, Value in self._Tags do
            New._Tags[Key] = Value
        end

        -- Copy or...
        for Index, Disjunction in self._Disjunction do
            New._Disjunction[Index] = Disjunction
        end

        -- Copy and...
        for Index, Conjunction in self._Conjunction do
            New._Conjunction[Index] = Conjunction
        end

        -- Copy constraints...
        for ConstraintName, Constraint in self._ActiveConstraints do
            New._ActiveConstraints[ConstraintName] = Constraint
        end

        New._Context = self._Context
        New._FailMessage = self._FailMessage
        New._LastConstraint = self._LastConstraint

        return New
    end

    --- Wraps & negates the last constraint (i.e. if it originally would fail, it passes, and vice versa).
    function TemplateClass:Negate()
        self = self:Copy()

        local LastConstraint = self._LastConstraint
        assert(LastConstraint ~= "", "Nothing to negate! (No constraints active)")
        self._ActiveConstraints[LastConstraint][4] = true

        return self
    end

    --- Sets a custom fail message to return if Check() fails. Also accepts a function which passes the value and context as arguments, expecting a formatted string showing the error.
    function TemplateClass:FailMessage(Message: string | ((any?, any?) -> (string)))
        ExpectType(Message, Expect.STRING_OR_FUNCTION, 1)

        self = self:Copy()
        self._FailMessage = Message
        return self
    end

    --- Sets a flag which caches the result of the last Check() call.
    function TemplateClass:Cached()
        return self:_AddTag("Cached")
    end

    --- Calling this will only check the type of the passed value if that value is not nil, i.e. it's an optional value so nothing can be passed, but if it is not nothing then it will be checked.
    function TemplateClass:Optional()
        return self:_AddTag("Optional")
    end

    --- Enqueues a new constraint to satisfy 'or' i.e. "check x or check y or check z or ..." must pass.
    function TemplateClass:Or(OtherType)
        if (type(OtherType) ~= "function") then
            AssertIsTypeBase(OtherType, 1)
        end

        self = self:Copy()
        table.insert(self._Disjunction, OtherType)
        return self
    end

    --- Enqueues a new constraint to satisfy 'and' i.e. "check x and check y and check z and ..." must pass.
    function TemplateClass:And(OtherType)
        AssertIsTypeBase(OtherType, 1)

        self = self:Copy()
        table.insert(self._Conjunction, OtherType)
        return self
    end

    --- Creates an Alias - useful for replacing large "Or" chains in big structures to identify where it is failing.
    function TemplateClass:Alias(AliasName)
        ExpectType(AliasName, Expect.STRING, 1)

        self = self:Copy()
        self._Alias = AliasName
        return self
    end

    --- Passes down a "context" value to constraints with functional values.
    --- We don't copy here because performance is important at the checking phase.
    function TemplateClass:WithContext(Context)
        self._Context = Context
        return self
    end

    --- Wraps a Check into its own callable function.
    function TemplateClass:AsPredicate()
        return function(Value)
            return self:_Check(Value)
        end
    end

    --- Wraps Assert into its own callable function.
    function TemplateClass:AsAssertion()
        return function(Value)
            return self:Assert(Value)
        end
    end

    --- Check (like above) except sets a universal context for the duration of the check.
    function TemplateClass:Check(Value)
        RootContext = self._Context
        local Success, Result = self:_Check(Value)
        RootContext = nil
        return Success, Result
    end

    --- Throws an error if the check is unsatisfied.
    function TemplateClass:Assert(Value)
        assert(self:Check(Value))
    end

    function TemplateClass:_AddConstraint(AllowOnlyOne, ConstraintName, Constraint, ...)
        if (AllowOnlyOne ~= nil) then
            ExpectType(AllowOnlyOne, Expect.BOOLEAN, 1)
        end

        ExpectType(ConstraintName, Expect.STRING, 2)
        ExpectType(Constraint, Expect.FUNCTION, 3)

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

    function TemplateClass:_AddTag(TagName)
        ExpectType(TagName, Expect.STRING, 1)

        if (self._Tags[TagName]) then
            error(`Tag already exists: {TagName}.`)
        end

        self = self:Copy()
        self._Tags[TagName] = true
        return self
    end

    ---- Internal Methods ----

    function TemplateClass:_CreateCache()
        local Cache = setmetatable({}, WEAK_KEY_MT); -- Weak keys because we don't want to leak Instances or tables.
        self._Cache = Cache
        return Cache
    end

    --- Checks if the value is of the correct type.
    function TemplateClass:_Check(Value)
        local CacheTag = self._Tags.Cached
        local Cache

        if (CacheTag) then
            Cache = self._Cache or self:_CreateCache()

            local CacheValue = Cache[Value or NegativeCacheValue]

            if (CacheValue) then
                return CacheValue[1], CacheValue[2]
            end
        end

        -- Handle "type x or type y or type z ...".
        -- We do this before checking constraints to check if any of the other conditions succeed.
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

        -- Handle "type x and type y and type z ..." - this is only really useful for objects and arrays.
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

        -- Optional allows the value to be nil, in which case it won't be checked and we can resolve.
        if (self._Tags.Optional and Value == nil) then
            if (CacheTag) then
                Cache[Value or NegativeCacheValue] = {true}
            end

            return true
        end

        -- Handle initial type check.
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

        -- Handle active constraints.
        for _, Constraint in self._ActiveConstraints do
            local Call = Constraint[1]
            local Args = Constraint[2]
            local HasFunctionalParams = Constraint[3]
            local ShouldNegate = Constraint[4]
            local ConstraintName = Constraint[5]

            -- Functional params -> transform into values when type checking.
            if (HasFunctionalParams) then
                Args = table.clone(Args)

                for Index, Arg in Args do
                    if (type(Arg) == "function") then
                        Args[Index] = Arg(RootContext)
                    end
                end
            end

            -- Call the constraint to verify it is satisfied.
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

    function TemplateClass:__tostring()
        -- User can create a unique alias to help simplify "where did it fail?".
        local Alias = self._Alias

        if (Alias) then
            return Alias
        end

        local Fields = {}

        -- Constraints list (including arg, possibly other type defs).
        local ActiveConstraints = self._ActiveConstraints

        if (next(ActiveConstraints) ~= nil) then
            local InnerConstraints = {}

            for _, Constraint in ActiveConstraints do
                table.insert(InnerConstraints, Constraint[5] .. "(" .. ConcatWithToString(Constraint[2], ", ") .. ")")
            end

            table.insert(Fields, "Constraints = {" .. ConcatWithToString(InnerConstraints, ", ") .. "}")
        end

        -- Alternatives field str.
        local Disjunction = self._Disjunction

        if (#Disjunction > 0) then
            local Alternatives = {}

            for _, AlternateType in Disjunction do
                table.insert(Alternatives, tostring(AlternateType))
            end

            table.insert(Fields, "Or = {" .. ConcatWithToString(Alternatives, ", ") .. "}")
        end

        -- Union fields str.
        local Conjunction = self._Conjunction

        if (#Conjunction > 0) then
            local Unions = {}

            for _, Union in Conjunction do
                table.insert(Unions, tostring(Union))
            end

            table.insert(Fields, "And = {" .. ConcatWithToString(Unions, ", ") .. "}")
        end

        local Context = self._Context

        if (Context) then
            table.insert(Fields, "Context = " .. tostring(Context))
        end

        return self.Type .. "(" .. ConcatWithToString(Fields, ", ") .. ")"
    end

    TemplateClass.GreaterThanOrEqualTo = GreaterThanOrEqualTo
    TemplateClass.LessThanOrEqualTo = LessThanOrEqualTo
    TemplateClass.IsAValueIn = IsAValueIn
    TemplateClass.GreaterThan = GreaterThan
    TemplateClass.IsAKeyIn = IsAKeyIn
    TemplateClass.LessThan = LessThan
    TemplateClass.Equals = Equals

    return function(...)
        return TemplateClass.new(...)
    end, TemplateClass
end

return {
    Create = CreateTemplate;

    BaseMethods = {
        GreaterThanOrEqualTo = GreaterThanOrEqualTo;
        LessThanOrEqualTo = LessThanOrEqualTo;
        IsAValueIn = IsAValueIn;
        GreaterThan = GreaterThan;
        IsAKeyIn = IsAKeyIn;
        LessThan = LessThan;
        Equals = Equals;
    };
}