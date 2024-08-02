--!native
--!optimize 2

local Or

local Util = require(script.Parent.Util)
    local ConcatWithToString = Util.ConcatWithToString
    local ByteSerializer = Util.ByteSerializer
        type ByteSerializer = typeof(ByteSerializer)
    local ExpectType = Util.ExpectType
    local Expect = Util.Expect

export type AnyMethod = (...any) -> (...any)
export type SignatureTypeChecker = {
    _TC: true;
}
export type SignatureTypeCheckerInternal = SignatureTypeChecker & { -- Stops Luau from complaining in the main script.
    GreaterThanOrEqualTo: AnyMethod;
    LessThanOrEqualTo: AnyMethod;
    DefineDeserialize: AnyMethod;
    DefineSerialize: AnyMethod;
    NonSerialized: AnyMethod;
    NoConstraints: AnyMethod;
    GreaterThan: AnyMethod;
    FailMessage: AnyMethod;
    AsPredicate: AnyMethod;
    WithContext: AnyMethod;
    AsAssert: AnyMethod;
    LessThan: AnyMethod;
    NoCheck: AnyMethod;
    Equals: AnyMethod;
    Assert: AnyMethod;
    Cached: AnyMethod;
    Negate: AnyMethod;
    Check: AnyMethod;
    Alias: AnyMethod;
    Copy: AnyMethod;

    _AddConstraint: AnyMethod;
    _CreateCache: AnyMethod;
    _AddTag: AnyMethod;
    _Check: AnyMethod;
}

export type TypeCheckerConstructor<T, P...> = ((P...) -> T)
export type FunctionalArg<T> = (T | ((any?) -> T))
export type SelfReturn<T, P...> = ((self: T, P...) -> T)

export type TypeChecker<ExtensionClass, SampleType> = {
    _TC: true;
    _P: SampleType;

    -- Methods available in all TypeCheckers.
    DefineDeserialize: ((self: ExtensionClass, Serializer: ((Serializer: ByteSerializer, Value: SampleType) -> ())) -> (ExtensionClass));
    DefineSerialize: ((self: ExtensionClass, Deserializer: ((Serializer: ByteSerializer) -> (SampleType))) -> (ExtensionClass));
    NonSerialized: ((self: ExtensionClass) -> (ExtensionClass));
    NoConstraints: ((self: ExtensionClass) -> (ExtensionClass));
    FailMessage: ((self: ExtensionClass, Message: FunctionalArg<string>) -> (ExtensionClass));
    AsAssertion: ((self: ExtensionClass) -> ((Input: SampleType) -> ()));
    AsPredicate: ((self: ExtensionClass) -> ((Input: SampleType) -> (boolean, string?)));
    Deserialize: ((self: ExtensionClass, Buffer: buffer, Atom: ("Bit" | "Byte")?, BypassCheck: boolean?) -> (SampleType));
    WithContext: ((self: ExtensionClass, Context: any?) -> (ExtensionClass));
    Serialize: ((self: ExtensionClass, Value: SampleType, Atom: ("Bit" | "Byte")?, BypassCheck: boolean?) -> (buffer));
    NoCheck: ((self: ExtensionClass) -> (ExtensionClass));
    Assert: ((self: ExtensionClass, Value: any) -> ());
    Negate: ((self: ExtensionClass) -> (ExtensionClass));
    Cached: ((self: ExtensionClass) -> (ExtensionClass));
    Check: ((self: ExtensionClass, Value: any) -> (boolean, string?));
    Alias: ((self: ExtensionClass, Alias: string) -> (ExtensionClass));
    Unmap: ((self: ExtensionClass, Unmapper: ((any?) -> (SampleType))) -> (ExtensionClass));
    Copy: ((self: ExtensionClass) -> (ExtensionClass));
    Map: ((self: ExtensionClass, Mapper: ((SampleType) -> (any?))) -> (ExtensionClass));

    -- Constraints available in all TypeCheckers.
    GreaterThanOrEqualTo: ((self: ExtensionClass, Value: FunctionalArg<SampleType>) -> (ExtensionClass));
    LessThanOrEqualTo: ((self: ExtensionClass, Value: FunctionalArg<SampleType>) -> (ExtensionClass));
    GreaterThan: ((self: ExtensionClass, Value: FunctionalArg<SampleType>) -> (ExtensionClass));
    LessThan: ((self: ExtensionClass, Value: FunctionalArg<SampleType>) -> (ExtensionClass));
    Equals: ((self: ExtensionClass, Value: FunctionalArg<SampleType>) -> (ExtensionClass));
};

local function Merge(X, Y)
    if (next(Y) == nil) then
        return X
    end
    local Result = table.clone(X)
    for Key, Value in Y do
        Result[Key] = Value
    end
    return Result
end

local function Join(X, Y)
    if (next(Y) == nil) then
        return X
    end
    local Result = table.clone(X)
    for _, Value in Y do
        table.insert(Result, Value)
    end
    return Result
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
    return self:_AddConstraint(false, "GreaterThan", function(_, Value, GTValue)
        if (Value > GTValue) then
            return true
        end

        return false, `Value {Value} is not greater than {GTValue}`
    end, GTValue)
end

local function LessThan(self, LTValue)
    return self:_AddConstraint(false, "LessThan", function(_, Value, LTValue)
        if (Value < LTValue) then
            return true
        end

        return false, `Value {Value} is not less than {LTValue}`
    end, LTValue)
end

local function GreaterThanOrEqualTo(self, GTEValue)
    return self:_AddConstraint(false, "GreaterThanOrEqualTo", function(_, Value, GTEValue)
        if (Value >= GTEValue) then
            return true
        end

        return false, `Value {Value} is not greater than or equal to {GTEValue}`
    end, GTEValue)
end

local function LessThanOrEqualTo(self, LTEValue)
    return self:_AddConstraint(false, "LessThanOrEqualTo", function(_, Value, LTEValue)
        if (Value <= LTEValue) then
            return true
        end

        return false, `Value {Value} is not less than or equal to {LTEValue}`
    end, LTEValue)
end

local function IsAValueIn(self, Table)
    ExpectType(Table, Expect.TABLE_OR_FUNCTION, 1)

    return self:_AddConstraint(false, "IsAValueIn", function(_, TargetValue, Table)
        for _, Value in Table do
            if (Value == TargetValue) then
                return true
            end
        end

        return false, `Value {TargetValue} was not found in table {Table}`
    end, Table)
end

local function IsAKeyIn(self, Table)
    ExpectType(Table, Expect.TABLE_OR_FUNCTION, 1)

    return self:_AddConstraint(false, "IsAKeyIn", function(_, TargetValue, Table)
        if (Table[TargetValue] == nil) then
            return false, `Key {TargetValue} was not found in table ({ConcatWithToString(Table, ", ")})`
        end

        return true
    end, Table)
end

local function EmptyFunction() end

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
            _ActiveConstraints = {};

            --[[
                _Cache = nil;
                _Context = nil;
                _FailMessage = nil;
            ]]
            _LastConstraint = 0;
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

        self:_Changed()
        
        -- Support for a single constraint passed as the constructor, with an arbitrary number of args.
        local InitialConstraint = self.InitialConstraint
        local NumArgs = select("#", ...)

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
        return table.clone(self)
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

    --- Bypasses the check on the type checker (i.e. for serialization speed).
    function TemplateClass:NoConstraints()
        return self:_AddTag("NoConstraints")
    end

    function TemplateClass:NoCheck()
        return self:_AddTag("NoCheck")
    end

    function TemplateClass:_MapCheckers(Mapper, Recursive)
        local Copy = self:Copy()
        local ConstraintsModify = {}

        for ConstraintIndex, Constraint in Copy._ActiveConstraints do
            local Args = Constraint[2]
            local ArgsModify = {}

            for ArgIndex, Arg in Args do
                if (type(Arg) ~= "table") then
                    continue
                end

                -- Case 1: arg is a checker.
                if (Arg._MapCheckers) then
                    ArgsModify[ArgIndex] = Mapper(Arg:_MapCheckers(Mapper, Recursive))
                    continue
                end

                -- Case 2: arg is a table of checkers.
                local _, FirstItem = next(Arg)
                if (type(FirstItem) == "table" and FirstItem._MapCheckers) then
                    local Changes = {}
                    for Index, Checker in Arg do
                        Changes[Index] = Mapper(Checker:_MapCheckers(Mapper, Recursive))
                    end
                    ArgsModify[ArgIndex] = Changes
                    continue
                end
            end

            if (next(ArgsModify) == nil) then
                continue
            end

            ConstraintsModify[ConstraintIndex] = Merge(Constraint, {[2] = Merge(Args, ArgsModify)})
        end

        Copy._ActiveConstraints = Merge(Copy._ActiveConstraints, ConstraintsModify)
        Copy:_UpdateSerialize()
        return Copy
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
        local Success, Result = self:Check(Value)
        assert(Success, Result)
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

        self._ActiveConstraints = Join(ActiveConstraints, {{Constraint, Args, HasFunctions, false, ConstraintName}})
        self._LastConstraint = #ActiveConstraints
        self:_Changed()
        return self
    end

    function TemplateClass:_Changed()
        -- Equals - return the value itself when deserialized in every case.
        -- No bits written or read from buffer.
        local Equals = self:GetConstraint("Equals")
        if (Equals) then
            if (self._Tags.NonSerialized) then
                return
            end
            local Value = Equals[1]
            self._Serialize = function(_, _, _) end
            self._Deserialize = function(_, _)
                return Value
            end
            self:_AddTag("NonSerialized")
            return
        end

        -- If it's a selection of possible values, we can use Or.
        -- Hacky cyclic dependency, but this is used because of String's ergonomic initial constraint & backwards compatibility.
        local IsAValueIn = self:GetConstraint("IsAValueIn")
        if (IsAValueIn and self.Type ~= "Or") then
            Or = Or or require(script.Parent.Core.Or) :: any

            local Serializer = Or():IsAValueIn(IsAValueIn[1])
                local DoDeserialize = Serializer._Deserialize
                local DoSerialize = Serializer._Serialize

            self._Serialize = function(Buffer, Value, Cache)
                DoSerialize(Buffer, Value, Cache)
            end
            self._Deserialize = function(Buffer, Cache)
                return DoDeserialize(Buffer, Cache)
            end

            return
        end

        local IsAKeyIn = self:GetConstraint("IsAKeyIn")
        if (IsAKeyIn and self.Type ~= "Or") then
            Or = Or or require(script.Parent.Core.Or) :: any

            local Serializer = Or():IsAKeyIn(IsAKeyIn[1])
                local DoDeserialize = Serializer._Deserialize
                local DoSerialize = Serializer._Serialize

            self._Serialize = function(Buffer, Value, Cache)
                DoSerialize(Buffer, Value, Cache)
            end
            self._Deserialize = function(Buffer, Cache)
                return DoDeserialize(Buffer, Cache)
            end

            return
        end

        -- Let the implementation update its _Serialize and _Deserialize functions.
        local UpdateSerialize = self._UpdateSerialize
        if (UpdateSerialize and not self._Tags.NonSerialized) then
            UpdateSerialize(self)
        end

        -- Allow manual definition to overwrite.
        self._Serialize = self._DefineSerialize or self._Serialize
        self._Deserialize = self._DefineDeserialize or self._Deserialize
    end

    function TemplateClass:_AddTag(TagName)
        ExpectType(TagName, Expect.STRING, 1)

        if (self._Tags[TagName]) then
            error(`Tag already exists: {TagName}.`)
        end

        self = self:Copy()
        self._Tags = Merge(self._Tags, {[TagName] = true})
        self:_Changed()
        return self
    end

    function TemplateClass:Map(Processor)
        self = self:Copy()
        self._Map = Processor
        return self
    end

    function TemplateClass:Unmap(Processor)
        self = self:Copy()
        self._Unmap = Processor
        return self
    end

    function TemplateClass:_HasFunctionalConstraints()
        for _, Constraint in self._ActiveConstraints do
            if (Constraint[3]) then
                return true
            end
        end
        return false
    end

    function TemplateClass:GetConstraint(ID)
        ExpectType(ID, Expect.STRING, 1)

        for Index, ConstraintData in self._ActiveConstraints do
            if (ConstraintData[5] == ID) then
                return ConstraintData[2], Index
            end
        end

        return nil, nil
    end

    function TemplateClass:GetConstraints(ID)
        ExpectType(ID, Expect.STRING, 1)

        local Result = {}
        for Index, ConstraintData in self._ActiveConstraints do
            if (ConstraintData[5] == ID) then
                table.insert(Result, ConstraintData[2])
            end
        end
        return Result
    end

    ---- Internal Methods ----

    function TemplateClass:_CreateCache()
        local Cache = setmetatable({}, WEAK_KEY_MT); -- Weak keys because we don't want to leak Instances or tables.
        self._Cache = Cache
        return Cache
    end

    --- Checks if the value is of the correct type.
    function TemplateClass:_Check(Value)
        local Tags = self._Tags
        if (Tags.NoCheck) then
            return true
        end

        local NoConstraintsTag = Tags.NoConstraints
        local CacheTag = Tags.Cached
        local Cache

        local Processor = self._Map
        Value = (Processor and Processor(Value) or Value)

        -- Handle any cached value.
        if (CacheTag) then
            Cache = self._Cache or self:_CreateCache()

            local CacheValue = Cache[Value or NegativeCacheValue]
            if (CacheValue) then
                return CacheValue[1], CacheValue[2]
            end
        end

        -- Handle initial type check.
        local Success, Message = self:_Initial(Value)
        if (not Success) then
            Message = self._FailMessage or Message

            if (CacheTag) then
                Cache[Value or NegativeCacheValue] = {false, Message}
            end

            return false, Message
        end

        -- No constraints tag -> only handle initial type check and no constraints.
        if (NoConstraintsTag) then
            return true
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

    function TemplateClass:DefineDeserialize(Deserializer)
        self = self:Copy()
        self._DefineDeserialize = Deserializer
        self._Deserialize = Deserializer
        return self
    end

    function TemplateClass:DefineSerialize(Serializer)
        self = self:Copy()
        self._DefineSerialize = Serializer
        self._Serialize = Serializer
        return self
    end

    function TemplateClass._Serialize(Buffer, Value)
        error(`Serialization not implemented for '{Name}'`)
    end

    function TemplateClass._Deserialize(Buffer)
        error(`Deserialization not implemented for '{Name}'`)
    end

    function TemplateClass:Serialize(Value, Atom, BypassCheck, Cache): buffer
        if (not BypassCheck) then
            self:Assert(Value)
        end
        Atom = Atom or "Byte"
    
        local Serializer = ByteSerializer(buffer.create(1))
        self._Serialize(Serializer, Value, Cache)
        return Serializer.GetClippedBuffer()
    end

    function TemplateClass:Deserialize(Buffer, Atom, BypassCheck, Cache): any
        Atom = Atom or "Byte"
    
        local Value = self._Deserialize(ByteSerializer(Buffer), Cache)
        if (not BypassCheck) then
            self:Assert(Value)
        end
        return Value
    end

    function TemplateClass:NonSerialized()
        self = self:_AddTag("NonSerialized")
        self._Deserialize = EmptyFunction
        self._Serialize = EmptyFunction
        return self
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

        local Context = self._Context
        if (Context) then
            table.insert(Fields, "Context = " .. tostring(Context))
        end

        return self.Type .. "(" .. ConcatWithToString(Fields, ", ") .. ")"
    end

    TemplateClass.GreaterThanOrEqualTo = GreaterThanOrEqualTo
    TemplateClass.LessThanOrEqualTo = LessThanOrEqualTo
    TemplateClass.GreaterThan = GreaterThan
    TemplateClass.IsAValueIn = IsAValueIn
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
        GreaterThan = GreaterThan;
        IsAValueIn = IsAValueIn;
        IsAKeyIn = IsAKeyIn;
        LessThan = LessThan;
        Equals = Equals;
    };
}