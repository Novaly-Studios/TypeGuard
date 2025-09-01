--!native
--!optimize 2

-- Allows easy command bar paste.
if (not script and Instance) then
    script = game:GetService("ReplicatedFirst").TypeGuard._Template
end

local Or

local Util = require(script.Parent.Util)
    local ConcatWithToString = Util.ConcatWithToString
    local ExpectType = Util.ExpectType
    local Expect = Util.Expect

local TableUtil = require(script.Parent.Parent.TableUtil).WithFeatures()
    local MergeDeep = TableUtil.Map.MergeDeep
    local Insert = TableUtil.Array.Insert
    local Merge = TableUtil.Map.Merge

local Serializers = require(script.Parent.Util.Serializers)
    local ByteSerializer = Serializers.Byte
    type Serializer = Serializers.Serializer

export type AnyMethod = (...any) -> (...any)

export type SignatureTypeChecker = {
    Deserialize: AnyMethod;
    Serialize: AnyMethod;
    Check: AnyMethod;
}

export type SignatureTypeCheckerInternal = SignatureTypeChecker & { -- Stops Luau from complaining in the main script.
    GreaterThanOrEqualTo: AnyMethod;
    LessThanOrEqualTo: AnyMethod;
    NoConstraints: AnyMethod;
    GreaterThan: AnyMethod;
    FailMessage: AnyMethod;
    AsPredicate: AnyMethod;
    WithContext: AnyMethod;
    RemapDeep: AnyMethod;
    AsAssert: AnyMethod;
    LessThan: AnyMethod;
    NoCheck: AnyMethod;
    Equals: AnyMethod;
    Assert: AnyMethod;
    Negate: AnyMethod;
    Check: AnyMethod;
    Copy: AnyMethod;
}

export type TypeCheckerConstructor<T, P...> = ((P...) -> T)
export type FunctionalArg<T> = (T | ((any?) -> T))

export type TypeChecker<ExtensionClass, SampleType> = {
    _TC: true;
    _C: {any};
    _P: SampleType;

    -- Methods available in all TypeCheckers.
    NoConstraints: ((self: ExtensionClass) -> (ExtensionClass));
    FailMessage: ((self: ExtensionClass, Message: FunctionalArg<string>) -> (ExtensionClass));
    AsAssertion: ((self: ExtensionClass) -> ((Input: SampleType) -> ()));
    AsPredicate: ((self: ExtensionClass) -> ((Input: SampleType) -> (boolean, string?)));
    Deserialize: ((self: ExtensionClass, Buffer: buffer, Serializer: Serializer?, BypassCheck: boolean?, Context: any?) -> (SampleType));
    WithContext: ((self: ExtensionClass, Context: any?) -> (ExtensionClass));
    RemapDeep: ((self: ExtensionClass, Mapper: ((any?) -> (any?)), Recursive: boolean?) -> (ExtensionClass));
    Serialize: ((self: ExtensionClass, Value: SampleType, Serializer: Serializer?, BypassCheck: boolean?, Context: any?) -> (buffer));
    NoCheck: ((self: ExtensionClass) -> (ExtensionClass));
    Assert: ((self: ExtensionClass, Value: any) -> ());
    Negate: ((self: ExtensionClass) -> (ExtensionClass));
    Modify: ((self: ExtensionClass, Modifications: {[any]: any}, ForceUpdate: boolean?) -> (ExtensionClass));
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
}

export type function AddConstraint(self: TypeChecker<any>, ID: string, Check: ((Type: any) -> ()))
    table.insert(self._C, {ID, Check})
end

local InitForbiddenKeys = false
local TemplateCache = {}
local ForbiddenKeys = { -- For repeated functions with essentially the same bytecode with different upvalues which would ruin the caching.
    _Serialize = true;
    _Deserialize = true;
}

local function _MemorizeSerialize(Target, Buffer, Level)
    local Type = typeof(Target)
    local LevelTabs = string.rep("\t", Level)
    local WriteString = Buffer.WriteString
    WriteString(LevelTabs, #LevelTabs * 8)
    WriteString(Type, #Type * 8)

    if (Type == "table" and (Level == 0 or Target._TC == nil)) then
        local NextLevel = Level + 1
        local Keys = {}

        for Key, Value in Target do
            if (ForbiddenKeys[Key]) then
                continue
            end

            table.insert(Keys, Key)
        end

        pcall(table.sort, Keys)

        for _, Key in Keys do
            WriteString("\n", 8)
            _MemorizeSerialize(Key, Buffer, NextLevel)
            WriteString("\n", 8)
            _MemorizeSerialize(Target[Key], Buffer, NextLevel)
        end

        return
    end

    local AsString = tostring(Target)
    WriteString(LevelTabs, #LevelTabs * 8)
    WriteString(AsString, #AsString * 8)
end

local function MemorizeSerialize(Target)
    local Buffer = Serializers.Byte(nil, 8192)
    Buffer.WriteString("\n", 8)
    _MemorizeSerialize(Target, Buffer, 0)
    return buffer.tostring(Buffer.GetClippedBuffer())
end

local function _Equals(_, Value, _, ExpectedValue)
    if (Value == ExpectedValue) then
        return true
    end

    return false, `Value {Value} does not equal {ExpectedValue}`
end

local function Equals(self, ExpectedValue)
    return self:_AddConstraint(true, "Equals", _Equals, ExpectedValue)
end

local function _GreaterThan(_, Value, _, GTValue)
    if (Value > GTValue) then
        return true
    end

    return false, `Value {Value} is not greater than {GTValue}`
end

local function GreaterThan(self, GTValue)
    return self:_AddConstraint(false, "GreaterThan", _GreaterThan, GTValue)
end

local function _LessThan(_, Value, _, LTValue)
    if (Value < LTValue) then
        return true
    end

    return false, `Value {Value} is not less than {LTValue}`
end

local function LessThan(self, LTValue)
    return self:_AddConstraint(false, "LessThan", _LessThan, LTValue)
end

local function _GreaterThanOrEqualTo(_, Value, _, GTEValue)
    if (Value >= GTEValue) then
        return true
    end

    return false, `Value {Value} is not greater than or equal to {GTEValue}`
end

local function GreaterThanOrEqualTo(self, GTEValue)
    return self:_AddConstraint(false, "GreaterThanOrEqualTo", _GreaterThanOrEqualTo, GTEValue)
end

local function _LessThanOrEqualTo(_, Value, _, LTEValue)
    if (Value <= LTEValue) then
        return true
    end

    return false, `Value {Value} is not less than or equal to {LTEValue}`
end

local function LessThanOrEqualTo(self, LTEValue)
    return self:_AddConstraint(false, "LessThanOrEqualTo", _LessThanOrEqualTo, LTEValue)
end

local function _IsAValueIn(_, TargetValue, _, Table)
    for _, Value in Table do
        if (Value == TargetValue) then
            return true
        end
    end

    return false, `Value {TargetValue} was not found in table {Table}`
end

local function IsAValueIn(self, Table)
    ExpectType(Table, Expect.TABLE_OR_FUNCTION, 1)

    return self:_AddConstraint(false, "IsAValueIn", _IsAValueIn, Table)
end

local function _IsAKeyIn(_, TargetValue, _, Table)
    if (Table[TargetValue] == nil) then
        return false, `Key {TargetValue} was not found in table ({ConcatWithToString(Table, ", ")})`
    end

    return true
end

local function IsAKeyIn(self, Table)
    ExpectType(Table, Expect.TABLE_OR_FUNCTION, 1)

    return self:_AddConstraint(false, "IsAKeyIn", _IsAKeyIn, Table)
end

local USE_INDEX = false

--- Creates a template TypeChecker object that can be used to extend behaviors via constraints.
local function CreateTemplate(Name: string)
    ExpectType(Name, Expect.STRING, 1)

    local TemplateClass = {
        InitialConstraintsDirectVariadic = nil;
        InitialConstraintsVariadic = nil;
        InitialConstraints = nil;
        InitialConstraint = nil;
        Name = Name;
        _TC = true;
    }
    TemplateClass.__index = TemplateClass

    function TemplateClass.new(...)
        local self = {
            _ActiveConstraints = {};

            --[[
                _UserContext = nil;
                _FailMessage = nil;
            ]]
            _LastConstraint = 0;
        }

        -- __index slows down benchmarks by ~10% at the expense of more memory usage.
        -- These objects are not meant to be rapidly constructed, so this is usually
        -- a good tradeoff.
        if (USE_INDEX) then
            setmetatable(self, TemplateClass)
        else
            for Key, Value in TemplateClass do
                if (Key == "new" or Key == "__index" or Key == "__tostring") then
                    continue
                end

                self[Key] = Value
            end

            setmetatable(self, {__tostring = (TemplateClass :: any).__tostring})
        end

        -- Make sure we generate initial serialization & deserialization functions.
        self = self:Modify({}, true)

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
                self = InitialConstraintsVariadic(self, (select(Index, ...)))
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

    local function GetCachedObject(self)
        local AsString = MemorizeSerialize(self)
        local Existing = TemplateCache[AsString]

        if (Existing) then
            return Existing
        end

        TemplateCache[AsString] = self
        return self
    end

    function TemplateClass:Modify(Modifications: {[any]: any}, ForceUpdate: boolean?)
        local Previous = self
        self = MergeDeep(self, Modifications, true)

        -- Top level will be the same if no changes were made deep in the object.
        if (self == Previous and not ForceUpdate) then
            return Previous
        end

        local ToMerge = self:_Changed()

        if (ToMerge == nil and not ForceUpdate) then
            return self
        end

        local Result = MergeDeep(self, ToMerge, false)
        return Result -- (Result._CacheConstruction and GetCachedObject(MergeDeep(self, ToMerge, false)) or Result)
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

    function TemplateClass:RemapDeep(Mapper, Recursive)
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
                                    if (Arg.RemapDeep) then
                                        NewArgs = MergeDeep(NewArgs, {
                                            [Index] = function(Arg)
                                                return Mapper(Arg:RemapDeep(Mapper, Recursive))
                                            end;
                                        }, true)

                                        continue
                                    end

                                    -- Case 2: arg is a table of checkers.
                                    local _, FirstItem = next(Arg)

                                    if (type(FirstItem) == "table" and FirstItem.RemapDeep) then
                                        local Changes = {}

                                        for Index, Checker in Arg do
                                            Changes[Index] = Mapper(Checker:RemapDeep(Mapper, Recursive))
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
    function TemplateClass:WithContext(Context)
        return self:Modify({
            _UserContext = Context;
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
        local InitCheck = self._InitCheck

        if (InitCheck) then
            InitCheck()
        end

        local UserContext = self._UserContext
        return self:_Check(Value, UserContext and {UserContext = UserContext} or nil)
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
        local Equals = self:GetConstraint("Equals")

        if (Equals) then
            local Value = Equals[1]

            return {
                _Serialize = function(Buffer, _, _)
                    local BufferContext = Buffer.Context

                    if (BufferContext) then
                        BufferContext("Template(Equals)")
                        BufferContext()
                    end
                end;
                _Deserialize = function(_, _)
                    return Value
                end;
            }
        end

        -- If it's a selection of possible values, we can use Or.
        -- Hacky cyclic dependency, but this is used because of String's ergonomic initial constraint & backwards compatibility.
        local IsAValueIn = self:GetConstraint("IsAValueIn")

        if (IsAValueIn and self.Name ~= "Or") then
            Or = Or or require(script.Parent.Core.Or) :: any

            local Serializer = Or():IsAValueIn(IsAValueIn[1])
                local DoDeserialize = Serializer._Deserialize
                local DoSerialize = Serializer._Serialize

            return {
                _Serialize = function(Buffer, Value, Context)
                    local BufferContext = Buffer.Context

                    if (BufferContext) then
                        BufferContext("Template(IsAValueIn)")
                    end

                    DoSerialize(Buffer, Value, Context)

                    if (BufferContext) then
                        BufferContext()
                    end
                end;
                _Deserialize = function(Buffer, Context)
                    return DoDeserialize(Buffer, Context)
                end;
            }
        end

        local IsAKeyIn = self:GetConstraint("IsAKeyIn")

        if (IsAKeyIn and self.Name ~= "Or") then
            Or = Or or require(script.Parent.Core.Or) :: any

            local Serializer = Or():IsAKeyIn(IsAKeyIn[1])
                local DoDeserialize = Serializer._Deserialize
                local DoSerialize = Serializer._Serialize

            return {
                _Serialize = function(Buffer, Value, Context)
                    local BufferContext = Buffer.Context

                    if (BufferContext) then
                        BufferContext("Template(IsAKeyIn)")
                    end

                    DoSerialize(Buffer, Value, Context)

                    if (BufferContext) then
                        BufferContext()
                    end
                end;
                _Deserialize = function(Buffer, Context)
                    return DoDeserialize(Buffer, Context)
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

    --- Quickly checks if a constraint exists on the type checker.
    function TemplateClass:HasConstraint(ID)
        local HasConstraintCache = self._HasConstraintCache

        if (not HasConstraintCache) then
            HasConstraintCache = {}

            for _, Constraint in self._ActiveConstraints do
                HasConstraintCache[Constraint.Name] = true
            end

            self._HasConstraintCache = HasConstraintCache
        end

        local Found = HasConstraintCache[ID]

        if (Found) then
            return Found
        end

        local Has = (self:GetConstraint(ID) ~= nil)
        HasConstraintCache[ID] = Has
        return Has
    end

    --- Gets the arguments for a constraint if it exists.
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
    function TemplateClass:_Check(Value, Context)
        if (self._NoCheck) then
            return true
        end

        local Processor = self._Map
        Value = (Processor and Processor(Value) or Value)

        -- Handle initial type check.
        local Success, Message = self:_Initial(Value, Context)

        if (not Success) then
            Message = self._FailMessage or Message
            return false, Message
        end

        -- No constraints tag -> only handle initial type check and no constraints.
        if (self._NoConstraints) then
            return true
        end

        -- Handle active constraints.
        for _, Constraint in self._ActiveConstraints do
            local HasFunctions = Constraint.HasFunctions
            local Negated = Constraint.Negated
            local Call = Constraint.Function
            local Args = Constraint.Args
            local Name = Constraint.Name

            -- Functional params -> transform into values when type checking.
            if (HasFunctions) then
                local UserContext = (Context and Context.UserContext or nil)
                Args = table.clone(Args)

                for Index, Arg in Args do
                    if (type(Arg) == "function") then
                        Args[Index] = Arg(UserContext)
                    end
                end
            end

            -- Call the constraint to verify it is satisfied.
            local SubSuccess, SubMessage = Call(self, Value, Context, unpack(Args))

            if (Negated) then
                SubMessage = if (SubSuccess) then
                                `Constraint '{Name}' succeeded but was expected to fail on value {Value}`
                                else
                                ""
                SubSuccess = not SubSuccess
            end

            if (not SubSuccess) then
                SubMessage = self._FailMessage or SubMessage
                return false, SubMessage
            end
        end

        return true
    end

    function TemplateClass._Serialize(Buffer, Value)
        error(`Serialization not implemented for '{Name}'`)
    end

    function TemplateClass._Deserialize(Buffer)
        error(`Deserialization not implemented for '{Name}'`)
    end

    function TemplateClass:Serialize(Value, Serializer, BypassCheck, Context)
        local InitSerialize = self._InitSerialize
        Context = Context or {}

        if (Context.BypassCheck == nil) then
            Context.BypassCheck = BypassCheck
        end

        if (InitSerialize) then
            local NewContext = InitSerialize(self, Context)

            if (NewContext) then
                Context = NewContext
            end
        end

        if (not BypassCheck) then
            self:Assert(Value)
        end

        Serializer = Serializer or ByteSerializer()
        self._Serialize(Serializer, Value, Context)
        return Serializer.GetClippedBuffer()
    end

    function TemplateClass:Deserialize(Buffer, Serializer, BypassCheck, Context)
        local InitDeserialize = self._InitDeserialize
        Context = Context or {}

        if (Context.BypassCheck == nil) then
            Context.BypassCheck = BypassCheck
        end

        if (InitDeserialize) then
            local NewContext = InitDeserialize(self, Context)

            if (NewContext) then
                Context = NewContext
            end
        end

        Serializer = Serializer or ByteSerializer(Buffer)
        Serializer.SetBuffer(Buffer)

        local Value = self._Deserialize(Serializer, Context)

        if (not BypassCheck) then
            self:Assert(Value)
        end

        return Value
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

        local UserContext = self._UserContext
        if (UserContext) then
            table.insert(Fields, "UserContext = " .. tostring(UserContext))
        end

        return self.Name .. "(" .. ConcatWithToString(Fields, ", ") .. ")"
    end ]]

    TemplateClass.GreaterThanOrEqualTo = GreaterThanOrEqualTo
    TemplateClass.LessThanOrEqualTo = LessThanOrEqualTo
    TemplateClass.GreaterThan = GreaterThan
    TemplateClass.IsAValueIn = IsAValueIn
    TemplateClass.IsAKeyIn = IsAKeyIn
    TemplateClass.LessThan = LessThan
    TemplateClass.Equals = Equals

    if (not InitForbiddenKeys) then
        for Key in TemplateClass do
            ForbiddenKeys[Key] = true
        end

        InitForbiddenKeys = true
    end

    return function(...)
        return TemplateClass.new(...)
    end, TemplateClass
end

return table.freeze({
    Create = CreateTemplate;

    BaseMethods = table.freeze({
        GreaterThanOrEqualTo = GreaterThanOrEqualTo;
        LessThanOrEqualTo = LessThanOrEqualTo;
        GreaterThan = GreaterThan;
        IsAValueIn = IsAValueIn;
        IsAKeyIn = IsAKeyIn;
        LessThan = LessThan;
        Equals = Equals;
    });
})