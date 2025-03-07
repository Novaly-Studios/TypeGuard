--!native
--!optimize 2

local Or

local Util = require(script.Parent.Util)
    local ConcatWithToString = Util.ConcatWithToString
    local ByteSerializer = Util.ByteSerializer
        type ByteSerializer = typeof(ByteSerializer)
    local BitSerializer = Util.BitSerializer
        type BitSerializer = typeof(BitSerializer)
    local ExpectType = Util.ExpectType
    local Expect = Util.Expect

local TableUtil = require(script.Parent.Parent.TableUtil).WithFeatures()
    local MergeDeep = TableUtil.Map.MergeDeep
    local Insert = TableUtil.Array.Insert
    local Merge = TableUtil.Map.Merge

export type AnyMethod = (...any) -> (...any)

export type SignatureTypeChecker = {
    _TC: true;
}

export type SignatureTypeCheckerInternal = SignatureTypeChecker & { -- Stops Luau from complaining in the main script.
    GreaterThanOrEqualTo: AnyMethod;
    LessThanOrEqualTo: AnyMethod;
    NoConstraints: AnyMethod;
    NonSerialized: AnyMethod;
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
    Copy: AnyMethod;
}

export type TypeCheckerConstructor<T, P...> = ((P...) -> T)
export type FunctionalArg<T> = (T | ((any?) -> T))
export type SelfReturn<T, P...> = ((self: T, P...) -> T)

export type TypeChecker<ExtensionClass, SampleType> = {
    _TC: true;
    _P: SampleType;

    -- Methods available in all TypeCheckers.
    NoConstraints: ((self: ExtensionClass) -> (ExtensionClass));
    NonSerialized: ((self: ExtensionClass) -> (ExtensionClass));
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

        -- Make sure we generate initial serialization & deserialization functions.
        self = MergeDeep(self, self:_Changed(), false)

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

    --- Wraps & negates the last constraint (i.e. if it originally would fail, it passes, and vice versa).
    function TemplateClass:Negate()
        local LastConstraint = self._LastConstraint
        assert(LastConstraint ~= 0, "Nothing to negate (no constraints active)")

        return self:Modify({
            _ActiveConstraints = {
                [LastConstraint] = {
                    Negated = function(Value)
                        return (not Value)
                    end;
                };
            };
        })
    end

    --- Sets a custom fail message to return if Check() fails. Also accepts a function which passes the value and context as arguments, expecting a formatted string showing the error.
    function TemplateClass:FailMessage(Message: string | ((any?, any?) -> (string)))
        ExpectType(Message, Expect.STRING_OR_FUNCTION, 1)

        return self:Modify({
            _FailMessage = Message;
        })
    end

    --- Sets a flag which caches the result of the last Check() call.
    function TemplateClass:Cached()
        return self:Modify({
            _Cached = true;
        })
    end

    --- Bypasses the check on the type checker (i.e. for serialization speed).
    function TemplateClass:NoConstraints()
        return self:Modify({
            _NoConstraints = true;
        })
    end

    function TemplateClass:NoCheck()
        return self:Modify({
            _NoCheck = true;
        })
    end

    function TemplateClass:Modify(Modifications: {[any]: any})
        local Previous = self
        self = MergeDeep(self, Modifications, true)

        -- Top level will be the same if no changes were made deep in the object.
        if (self == Previous) then
            return self
        end

        local ToMerge = self:_Changed()

        if (ToMerge == nil) then
            return self
        end

        return MergeDeep(self, ToMerge, false)
    end

    function TemplateClass:ModifyConstraints(ID, Modifier)
        local ActiveConstraints = self._ActiveConstraints

        for ConstraintIndex, Constraint in ActiveConstraints do
            if (Constraint.Name == ID) then
                self = self:Modify({
                    _ActiveConstraints = {
                        [ConstraintIndex] = {
                            Args = Modifier;
                        };
                    };
                })
            end
        end

        return self
    end

    function TemplateClass:_MapCheckers(Mapper, Recursive)
        --[[ local Copy = table.clone(self)
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
        return Copy ]]

        return self:Modify({
            _ActiveConstraints = function(ActiveConstraints)
                for ConstraintIndex, Constraint in ActiveConstraints do
                    ActiveConstraints = MergeDeep(ActiveConstraints, {
                        [ConstraintIndex] = {
                            Args = function(Args)
                                local NewArgs = Args

                                for Index, Arg in Args do
                                    if (type(Arg) ~= "table") then
                                        continue
                                    end

                                    -- Case 1: arg is a checker.
                                    if (Arg._MapCheckers) then
                                        NewArgs = MergeDeep(NewArgs, {
                                            [Index] = function(Arg)
                                                return Mapper(Arg:_MapCheckers(Mapper, Recursive))
                                            end;
                                        }, true)

                                        continue
                                    end

                                    -- Case 2: arg is a table of checkers.
                                    local _, FirstItem = next(Arg)

                                    if (type(FirstItem) == "table" and FirstItem._MapCheckers) then
                                        local Changes = {}

                                        for Index, Checker in Arg do
                                            Changes[Index] = Mapper(Checker:_MapCheckers(Mapper, Recursive))
                                        end

                                        NewArgs = MergeDeep(NewArgs, {
                                            [Index] = Changes;
                                        }, true)

                                        continue
                                    end
                                end

                                return NewArgs
                            end;
                        };
                    }, true)
                end

                return ActiveConstraints
            end
        })
    end

    --- Passes down a "context" value to constraints with functional values.
    --- We don't copy here because performance is important at the checking phase.
    function TemplateClass:WithContext(Context)
        return self:Modify({
            _Context = Context;
        })
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

    function TemplateClass:_AddConstraint(AllowOnlyOne, Name, Constraint, ...)
        if (AllowOnlyOne ~= nil) then
            ExpectType(AllowOnlyOne, Expect.BOOLEAN, 1)
        end

        ExpectType(Name, Expect.STRING, 2)
        ExpectType(Constraint, Expect.FUNCTION, 3)

        local Args = {...}
        local HasFunctions = false
        local ActiveConstraints = self._ActiveConstraints

        -- Find any functional constraints.
        for Index, Value in Args do
            if (type(Value) == "function") then
                HasFunctions = true
                break
            end
        end

        if (AllowOnlyOne) then
            local Found = false
            for _, ConstraintData in ActiveConstraints do
                if (ConstraintData.Name == Name) then
                    Found = true
                    break
                end
            end
            if (Found) then
                error(`Attempt to apply a constraint marked as 'only once' more than once: {Name}.`)
            end
        end

        return self:Modify({
            _ActiveConstraints = function(ActiveConstraints)
                return Insert(ActiveConstraints or {}, {
                    HasFunctions = HasFunctions;
                    Function = Constraint;
                    Negated = false;
                    Name = Name;
                    Args = Args;
                })
            end;
            _LastConstraint = function(Value)
                return (Value or 0) + 1
            end;
        })
    end

    function TemplateClass:_Changed()
        -- Equals - return the value itself when deserialized in every case.
        -- No bits written or read from buffer.
        if (self._NonSerialized) then
            return {
                _Serialize = function(_, _, _) end;
                _Deserialize = function(_, _) end;
            }
        end

        local Equals = self:GetConstraint("Equals")

        if (Equals) then
            local Value = Equals[1]

            return {
                _Serialize = function(_, _, _) end;
                _Deserialize = function(_, _)
                    return Value
                end;
            }
        end

        -- If it's a selection of possible values, we can use Or.
        -- Hacky cyclic dependency, but this is used because of String's ergonomic initial constraint & backwards compatibility.
        local IsAValueIn = self:GetConstraint("IsAValueIn")

        if (IsAValueIn and self.Type ~= "Or") then
            Or = Or or require(script.Parent.Core.Or) :: any

            local Serializer = Or():IsAValueIn(IsAValueIn[1])
                local DoDeserialize = Serializer._Deserialize
                local DoSerialize = Serializer._Serialize

            return {
                _Serialize = function(Buffer, Value, Cache)
                    DoSerialize(Buffer, Value, Cache)
                end;
                _Deserialize = function(Buffer, Cache)
                    return DoDeserialize(Buffer, Cache)
                end;
            }
        end

        local IsAKeyIn = self:GetConstraint("IsAKeyIn")

        if (IsAKeyIn and self.Type ~= "Or") then
            Or = Or or require(script.Parent.Core.Or) :: any

            local Serializer = Or():IsAKeyIn(IsAKeyIn[1])
                local DoDeserialize = Serializer._Deserialize
                local DoSerialize = Serializer._Serialize

            return {
                _Serialize = function(Buffer, Value, Cache)
                    DoSerialize(Buffer, Value, Cache)
                end;
                _Deserialize = function(Buffer, Cache)
                    return DoDeserialize(Buffer, Cache)
                end;
            }
        end

        -- Let the implementation update its _Serialize and _Deserialize functions.
        local UpdateSerialize = self._UpdateSerialize
        local ToMerge

        if (UpdateSerialize) then
            ToMerge = UpdateSerialize(self)
        end

        -- Allow manual definition to overwrite.
        return Merge({
            _Serialize = self._Serialize;
            _Deserialize = self._Deserialize;
        }, ToMerge or {})
    end

    function TemplateClass:Map(Processor)
        return self:Modify({
            _Map = function(_)
                return Processor
            end;
        })
    end

    function TemplateClass:Unmap(Processor)
        return self:Modify({
            _Unmap = function(_)
                return Processor
            end;
        })
    end

    function TemplateClass:_HasFunctionalConstraints()
        for _, Constraint in self._ActiveConstraints do
            if (Constraint.HasFunctions) then
                return true
            end
        end

        return false
    end

    function TemplateClass:GetConstraint(ID)
        ExpectType(ID, Expect.STRING, 1)

        for Index, ConstraintData in self._ActiveConstraints do
            if (ConstraintData.Name == ID) then
                return ConstraintData.Args, Index
            end
        end

        return nil, nil
    end

    function TemplateClass:GetConstraints(ID)
        ExpectType(ID, Expect.STRING, 1)

        local Result = {}

        for Index, ConstraintData in self._ActiveConstraints do
            if (ConstraintData.Name == ID) then
                table.insert(Result, ConstraintData.Args)
            end
        end

        return Result
    end

    --- Checks if the value is of the correct type.
    function TemplateClass:_Check(Value)
        if (self._NoCheck) then
            return true
        end

        local CacheTag = self._Cached
        local Cache

        local Processor = self._Map
        Value = (Processor and Processor(Value) or Value)

        -- Handle any cached value.
        if (CacheTag) then
            Cache = self._Cache
            if (not Cache) then
                Cache = setmetatable({}, WEAK_KEY_MT); -- Weak keys because we don't want to leak Instances or tables.
                self._Cache = Cache
            end

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
        if (self._NoConstraints) then
            return true
        end

        -- Handle active constraints.
        for _, Constraint in self._ActiveConstraints do
            local HasFunctionalParams = Constraint.HasFunctions
            local Negated = Constraint.Negated
            local Call = Constraint.Function
            local Args = Constraint.Args
            local Name = Constraint.Name

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

            if (Negated) then
                SubMessage = if (SubSuccess) then
                                `Constraint '{Name}' succeeded but was expected to fail on value {Value}`
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

    function TemplateClass._Serialize(Buffer, Value)
        error(`Serialization not implemented for '{Name}'`)
    end

    function TemplateClass._Deserialize(Buffer)
        error(`Deserialization not implemented for '{Name}'`)
    end

    function TemplateClass:Serialize(Value, Atom, BypassCheck, Cache)
        if (not BypassCheck) then
            self:Assert(Value)
        end

        local Serializer = ((Atom or "Byte") == "Byte" and ByteSerializer or BitSerializer)(buffer.create(1))
        local PreSerialize = self.PreSerialize

        if (PreSerialize) then
            PreSerialize(self, Serializer, Cache)
        end

        self._Serialize(Serializer, Value, Cache)
        return Serializer.GetClippedBuffer()
    end

    function TemplateClass:Deserialize(Buffer, Atom, BypassCheck, Cache)
        local Deserializer = ((Atom or "Byte") == "Byte" and ByteSerializer or BitSerializer)(Buffer)
        local PreDeserialize = self.PreDeserialize
        local Value

        if (PreDeserialize) then
            Value = PreDeserialize(self, Deserializer, Cache)
        end

        Value = Value or self._Deserialize(Deserializer, Cache)

        if (not BypassCheck) then
            self:Assert(Value)
        end

        return Value
    end

    function TemplateClass:NonSerialized()
        return self:Modify({
            _NonSerialized = true;
        })
    end

    --[[ function TemplateClass:__tostring()
        local Fields = {}

        -- Constraints list (including arg, possibly other type defs).
        local ActiveConstraints = self._ActiveConstraints
        if (next(ActiveConstraints) ~= nil) then
            local InnerConstraints = {}

            for _, Constraint in ActiveConstraints do
                table.insert(InnerConstraints, Constraint.Name .. "(" .. ConcatWithToString(Constraint.Args, ", ") .. ")")
            end

            table.insert(Fields, "Constraints = {" .. ConcatWithToString(InnerConstraints, ", ") .. "}")
        end

        local Context = self._Context
        if (Context) then
            table.insert(Fields, "Context = " .. tostring(Context))
        end

        return self.Type .. "(" .. ConcatWithToString(Fields, ", ") .. ")"
    end ]]

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