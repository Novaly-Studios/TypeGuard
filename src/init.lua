--!nonstrict
--[[
    Quick usage reference (more examples )

    local CHECK_METHOD = Types.Params(
        Types.String(),
        Types.Number():Or(Types.Boolean()):Optional(),
        Types.Array():OfType(Types.Number())
    )

    function Class:Method(Arg1: string, Arg2: (number | boolean)?, Arg3: {number})
        CHECK_METHOD(Arg1, Arg2, Arg3)
    end
]]

local EMPTY_STRING = ""
local INVALID_ARGUMENT = "Invalid argument #%d (%s expected, got %s)"

local function ExpectType(PassedArg: any, ExpectedType: string, ArgNumber: number)
    local GotType = typeof(PassedArg)
    assert(GotType == ExpectedType, INVALID_ARGUMENT:format(ArgNumber, ExpectedType, GotType))
end

local function ConcatWithToString(Array: {any}, Separator: string): string
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

local STRUCTURE_TO_FLAT_STR_MT = {
    __tostring = function(self)
        local Pairings = {}

        for Key, Value in pairs(self) do
            table.insert(Pairings, tostring(Key) .. " = " .. tostring(Value))
        end

        return "{" .. ConcatWithToString(Pairings, ", ") .. "}"
    end;
}

-- Standard re-usable functions throughout all type checkers
    local function IsAKeyIn(self, ...)
        return self:_AddConstraint("IsAKeyIn", function(_, Key, Store)
            return Store[Key] ~= nil, "No key found in table: " .. tostring(Store)
        end, ...)
    end

    local function IsAValueIn(self, ...)
        return self:_AddConstraint("IsAValueIn", function(_, TargetValue, Store)
            for _, Value in pairs(Store) do
                if (Value == TargetValue) then
                    return true, EMPTY_STRING
                end
            end

            return false, "No value found in table: " .. tostring(Store)
        end, ...)
    end

    local function Equals(self, ...)
        return self:_AddConstraint("Equals", function(_, Value, ExpectedValue)
            return Value == ExpectedValue, "Number does not equal " .. tostring(ExpectedValue)
        end, ...)
    end

    local function GreaterThan(self, ...)
        return self:_AddConstraint("GreaterThan", function(_, Value, ExpectedValue)
            return Value > ExpectedValue, "Number is not greater than " .. tostring(ExpectedValue)
        end, ...)
    end

    local function LessThan(self, ...)
        return self:_AddConstraint("LessThan", function(_, Value, ExpectedValue)
            return Value < ExpectedValue, "Number is not less than " .. tostring(ExpectedValue)
        end, ...)
    end



local Types = {}

type TypeCheckerConstraintFunction = (TypeCheckerObject, any...) -> (TypeCheckerObject);
type TypeCheckerObject = {
    _Copy: (TypeCheckerObject) -> TypeCheckerObject;
    _AddConstraint: (TypeCheckerObject, string, (any...) -> (TypeCheckerObject), ...any) -> ();

    Or: (TypeCheckerObject, TypeCheckerObject) -> (TypeCheckerObject);
    And: (TypeCheckerObject, TypeCheckerObject) -> (TypeCheckerObject);
    Alias: (TypeCheckerObject, string) -> (TypeCheckerObject);
    AddTag: (TypeCheckerObject, string) -> (TypeCheckerObject);
    Optional: (TypeCheckerObject) -> (TypeCheckerObject);

    WrapCheck: (TypeCheckerObject) -> ((any) -> (boolean, string));
    WrapAssert: (TypeCheckerObject) -> ((any) -> ());
    Check: (TypeCheckerObject, any) -> (string, boolean);
    Assert: (TypeCheckerObject, any) -> ();
}
type TypeCreatorFunction<T> = (any...) -> (T)

function Types.Template(Name)
    ExpectType(Name, "string", 1)

    local TemplateClass = {}
    TemplateClass.__index = TemplateClass
    TemplateClass._IsTemplate = true
    TemplateClass._Type = Name

    function TemplateClass.new(...)
        local self = {
            _Tags = {};
            _Disjunction = {};
            _Conjunction = {};
            _ActiveConstraints = {};
        }

        setmetatable(self, TemplateClass)

        if (TemplateClass._InitialConstraint and select("#", ...) > 0) then
            return self:_InitialConstraint(...)
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
    function TemplateClass:_AddConstraint(ConstraintName, Constraint, ...): TypeCheckerObject
        ExpectType(ConstraintName, "string", 1)
        ExpectType(Constraint, "function", 2)

        self = self:_Copy()

        local ActiveConstraints = self._ActiveConstraints
        assert(ActiveConstraints[ConstraintName] == nil, "Constraint already exists: " .. ConstraintName)
        ActiveConstraints[ConstraintName] = {Constraint, {...}}
        return self
    end

    function TemplateClass:Optional()
        return self:AddTag("Optional")
    end

    function TemplateClass:Or(OtherType)
        Types._AssertIsTypeBase(OtherType)

        self = self:_Copy()
        table.insert(self._Disjunction, OtherType)
        return self
    end

    function TemplateClass:And(OtherType)
        Types._AssertIsTypeBase(OtherType)

        self = self:_Copy()
        table.insert(self._Conjunction, OtherType)
        return self
    end

    function TemplateClass:Alias(AliasName)
        ExpectType(AliasName, "string", 1)

        self = self:_Copy()
        self._Alias = AliasName
        return self
    end

    function TemplateClass:AddTag(TagName)
        ExpectType(TagName, "string", 1)

        self = self:_Copy()
        self._Tags[TagName] = true
        return self
    end

    function TemplateClass:WrapCheck()
        return function(...)
            return self:Check(...)
        end
    end

    function TemplateClass:WrapAssert()
        return function(...)
            return self:Assert(...)
        end
    end

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

    function TemplateClass:Assert(...)
        assert(self:Check(...))
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

    return function(...)
        return TemplateClass.new(...)
    end, TemplateClass
end

--- Checks if an object contains the fields which define a type template from this module
function Types._AssertIsTypeBase(Subject)
    ExpectType(Subject, "table", 1)

    assert(Subject._Tags ~= nil, "Subject does not contain _Tags field")
    assert(Subject._ActiveConstraints ~= nil, "Subject does not contain _ActiveConstraints field")
    assert(Subject._Disjunction ~= nil, "Subject does not contain _Disjunction field")
    assert(Subject._Conjunction ~= nil, "Subject does not contain _Conjunction field")
end

--- Cheap & easy way to create a type without any constraints, and just an initial check corresponding to Roblox's typeof
function Types.FromTypeName(TypeName)
    ExpectType(TypeName, "string", 1)

    local CheckerFunction, Checker = Types.Template(TypeName)

    function Checker:_Initial(Input)
        if (typeof(Input) ~= TypeName) then
            return false, "Expected " .. TypeName .. ", got " .. typeof(Input)
        end

        return true, EMPTY_STRING
    end

    Checker.Equals = Equals
    Checker.equals = Equals
    Checker.IsAValueIn = IsAValueIn
    Checker.isAValueIn = IsAValueIn
    Checker.IsAKeyIn = IsAKeyIn
    Checker.isAKeyIn = IsAKeyIn
    Checker.ValueOf = IsAValueIn
    Checker.valueOf = IsAValueIn
    Checker.KeyOf = IsAKeyIn
    Checker.keyOf = IsAKeyIn

    return CheckerFunction
end
Types.fromTypeName = Types.FromTypeName




do
    type NumberTypeCheckerObject = TypeCheckerObject & {
        Integer: TypeCheckerConstraintFunction;
        Int: TypeCheckerConstraintFunction;
        int: NumberTypeCheckerObject;

        Decimal: NumberTypeCheckerObject;
        decimal: NumberTypeCheckerObject;

        Min: NumberTypeCheckerObject;
        min: NumberTypeCheckerObject;

        Max: NumberTypeCheckerObject;
        max: NumberTypeCheckerObject;

        Range: NumberTypeCheckerObject;
        range: NumberTypeCheckerObject;

        Equals: NumberTypeCheckerObject;
        equals: NumberTypeCheckerObject;

        IsAValueIn: NumberTypeCheckerObject;
        isAValueIn: NumberTypeCheckerObject;

        IsAKeyIn: NumberTypeCheckerObject;
        isAKeyIn: NumberTypeCheckerObject;

        ValueOf: NumberTypeCheckerObject;
        valueOf: NumberTypeCheckerObject;

        KeyOf: NumberTypeCheckerObject;
        keyOf: NumberTypeCheckerObject;

        GreaterThan: NumberTypeCheckerObject;
        greaterThan: NumberTypeCheckerObject;

        LessThan: NumberTypeCheckerObject;
        lessThan: NumberTypeCheckerObject;
    }

    local Number: TypeCreatorFunction<NumberTypeCheckerObject>, NumberClass = Types.Template("Number")

    function NumberClass:_Initial(Item)
        return typeof(Item) == "number", "Expected number, got " .. typeof(Item)
    end

    function NumberClass:Integer(...)
        return self:_AddConstraint("Integer", function(_, Item)
            return math.floor(Item) == Item, "Expected integer form, got " .. tostring(Item)
        end, ...)
    end
    NumberClass.integer = NumberClass.Integer
    NumberClass.Int = NumberClass.Integer
    NumberClass.int = NumberClass.Integer

    function NumberClass:Decimal(...)
        return self:_AddConstraint("Decimal", function(_, Item)
            return math.floor(Item) ~= Item, "Expected decimal form, got " .. tostring(Item)
        end, ...)
    end
    NumberClass.decimal = NumberClass.Decimal

    function NumberClass:Min(...)
        return self:_AddConstraint("Min", function(_, Item, Min)
            return Item >= Min, "Length must be at least " .. tostring(Min) .. ", got " .. tostring(Item)
        end, ...)
    end
    NumberClass.min = NumberClass.Min

    function NumberClass:Max(...)
        return self:_AddConstraint("Max", function(_, Item, Max)
            return Item <= Max, "Length must be at most " .. tostring(Max) .. ", got " .. tostring(Item)
        end, ...)
    end
    NumberClass.max = NumberClass.Max

    function NumberClass:Range(...)
        return self:_AddConstraint("Range", function(_, Item, Min, Max)
            return Item >= Min and Item <= Max, "Length must be between " .. tostring(Min) .. " and " .. tostring(Max) .. ", got " .. tostring(Item)
        end, ...)
    end
    NumberClass.range = NumberClass.Range

    NumberClass.Equals = Equals
    NumberClass.equals = Equals
    NumberClass.IsAValueIn = IsAValueIn
    NumberClass.isAValueIn = IsAValueIn
    NumberClass.IsAKeyIn = IsAKeyIn
    NumberClass.isAKeyIn = IsAKeyIn
    NumberClass.ValueOf = IsAValueIn
    NumberClass.valueOf = IsAValueIn
    NumberClass.KeyOf = IsAKeyIn
    NumberClass.keyOf = IsAKeyIn
    NumberClass.GreaterThan = GreaterThan
    NumberClass.greaterThan = GreaterThan
    NumberClass.LessThan = LessThan
    NumberClass.lessThan = LessThan

    Types.Number = Number
    Types.number = Number
end




do
    type StringTypeCheckerObject = TypeCheckerObject & {
        MinLength: StringTypeCheckerObject;
        minLength: StringTypeCheckerObject;

        MaxLength: StringTypeCheckerObject;
        maxLength: StringTypeCheckerObject;

        LengthRange: StringTypeCheckerObject;
        lengthRange: StringTypeCheckerObject;

        Pattern: StringTypeCheckerObject;
        pattern: StringTypeCheckerObject;

        Equals: StringTypeCheckerObject;
        equals: StringTypeCheckerObject;

        IsAValueIn: StringTypeCheckerObject;
        isAValueIn: StringTypeCheckerObject;

        IsAKeyIn: StringTypeCheckerObject;
        isAKeyIn: StringTypeCheckerObject;

        ValueOf: StringTypeCheckerObject;
        valueOf: StringTypeCheckerObject;

        KeyOf: StringTypeCheckerObject;
        keyOf: StringTypeCheckerObject;
    }

    local String: TypeCreatorFunction<StringTypeCheckerObject>, StringClass = Types.Template("String")

    function StringClass:_Initial(Item)
        return typeof(Item) == "string", "Expected string, got " .. typeof(Item)
    end

    function StringClass:MinLength(...)
        return self:_AddConstraint("MinLength", function(_, Item, MinLength)
            return #Item >= MinLength, "Length must be at least " .. MinLength .. ", got " .. #Item
        end, ...)
    end
    StringClass.minLength = StringClass.MinLength

    function StringClass:MaxLength(...)
        return self:_AddConstraint("MaxLength", function(_, Item, MaxLength)
            return #Item <= MaxLength, "Length must be at most " .. MaxLength .. ", got " .. #Item
        end, ...)
    end
    StringClass.maxLength = StringClass.MaxLength

    function StringClass:LengthRange(...)
        return self:_AddConstraint("LengthRange", function(_, Item, MinLength, MaxLength)
            return #Item >= MinLength and #Item <= MaxLength, "Length must be between " .. MinLength .. " and " .. MaxLength .. ", got " .. #Item
        end, ...)
    end
    StringClass.lengthRange = StringClass.LengthRange

    function StringClass:Pattern(...)
        return self:_AddConstraint("Pattern", function(_, Item, Pattern)
            return string.match(Item, Pattern) ~= nil, "String does not match pattern " .. tostring(Pattern)
        end, ...)
    end
    StringClass.pattern = StringClass.Pattern

    StringClass.Equals = Equals
    StringClass.equals = Equals
    StringClass.IsAValueIn = IsAValueIn
    StringClass.isAValueIn = IsAValueIn
    StringClass.IsAKeyIn = IsAKeyIn
    StringClass.isAKeyIn = IsAKeyIn
    StringClass.ValueOf = IsAValueIn
    StringClass.valueOf = IsAValueIn
    StringClass.KeyOf = IsAKeyIn
    StringClass.keyOf = IsAKeyIn

    Types.String = String
    Types.string = String
end




do
    type ArrayTypeCheckerObject = TypeCheckerObject & {
        Length: ArrayTypeCheckerObject;
        length: ArrayTypeCheckerObject;

        OfLength: ArrayTypeCheckerObject;
        ofLength: ArrayTypeCheckerObject;

        Size: ArrayTypeCheckerObject;
        size: ArrayTypeCheckerObject;

        LengthEquals: ArrayTypeCheckerObject;
        lengthEquals: ArrayTypeCheckerObject;

        MinLength: ArrayTypeCheckerObject;
        minLength: ArrayTypeCheckerObject;

        MaxLength: ArrayTypeCheckerObject;
        maxLength: ArrayTypeCheckerObject;

        LengthRange: ArrayTypeCheckerObject;
        lengthRange: ArrayTypeCheckerObject;

        LengthBetween: ArrayTypeCheckerObject;
        lengthBetween: ArrayTypeCheckerObject;

        Contains: ArrayTypeCheckerObject;
        contains: ArrayTypeCheckerObject;

        HasItem: ArrayTypeCheckerObject;
        hasItem: ArrayTypeCheckerObject;

        HasValue: ArrayTypeCheckerObject;
        hasValue: ArrayTypeCheckerObject;

        OfType: ArrayTypeCheckerObject;
        ofType: ArrayTypeCheckerObject;

        OfStructure: ArrayTypeCheckerObject;
        ofStructure: ArrayTypeCheckerObject;

        StructuralEquals: ArrayTypeCheckerObject;
        structuralEquals: ArrayTypeCheckerObject;

        Strict: ArrayTypeCheckerObject;
        strict: ArrayTypeCheckerObject;

        Equals: ArrayTypeCheckerObject;
        equals: ArrayTypeCheckerObject;

        IsAValueIn: ArrayTypeCheckerObject;
        isAValueIn: ArrayTypeCheckerObject;

        IsAKeyIn: ArrayTypeCheckerObject;
        isAKeyIn: ArrayTypeCheckerObject;

        ValueOf: ArrayTypeCheckerObject;
        valueOf: ArrayTypeCheckerObject;

        KeyOf: ArrayTypeCheckerObject;
        keyOf: ArrayTypeCheckerObject;
    }

    local PREFIX_ARRAY = "Index"
    local PREFIX_PARAM = "Param"
    local ERR_PREFIX = "[%s '%d'] "
    local ERR_INDEX_NIL = ERR_PREFIX .. "Expected non-nil value, got nil"
    local ERR_UNEXPECTED_VALUE = ERR_PREFIX .. " Unexpected value (strict tag is present)"

    local Array: TypeCreatorFunction<ArrayTypeCheckerObject>, ArrayClass = Types.Template("Array")

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

    function ArrayClass:Length(...)
        return self:_AddConstraint("Length", function(_, TargetArray, Length)
            return #TargetArray == Length, "Length must be " .. Length .. ", got " .. #TargetArray
        end, ...)
    end
    ArrayClass.length = ArrayClass.Length
    ArrayClass.OfLength = ArrayClass.Length
    ArrayClass.ofLength = ArrayClass.Length
    ArrayClass.Size = ArrayClass.Length
    ArrayClass.size = ArrayClass.Length
    ArrayClass.LengthEquals = ArrayClass.Length
    ArrayClass.lengthEquals = ArrayClass.Length

    function ArrayClass:MinLength(...)
        return self:_AddConstraint("MinLength", function(_, TargetArray, MinLength)
            return #TargetArray >= MinLength, "Length must be at least " .. MinLength .. ", got " .. #TargetArray
        end, ...)
    end
    ArrayClass.minLength = ArrayClass.MinLength

    function ArrayClass:MaxLength(...)
        return self:_AddConstraint("MaxLength", function(_, TargetArray, MaxLength)
            return #TargetArray <= MaxLength, "Length must be at most " .. MaxLength .. ", got " .. #TargetArray
        end, ...)
    end
    ArrayClass.maxLength = ArrayClass.MaxLength

    function ArrayClass:LengthRange(...)
        return self:_AddConstraint("LengthRange", function(_, TargetArray, MinLength, MaxLength)
            return #TargetArray >= MinLength and #TargetArray <= MaxLength, "Length must be between " .. MinLength .. " and " .. MaxLength .. ", got " .. #TargetArray
        end, ...)
    end
    ArrayClass.lengthRange = ArrayClass.LengthRange
    ArrayClass.LengthBetween = ArrayClass.LengthRange
    ArrayClass.lengthBetween = ArrayClass.LengthRange

    function ArrayClass:Contains(...)
        return self:_AddConstraint("Contains", function(_, TargetArray, Value, StartPoint)
            return table.find(TargetArray, Value, StartPoint) ~= nil, "Value not found in array: " .. tostring(Value)
        end, ...)
    end
    ArrayClass.contains = ArrayClass.Contains
    ArrayClass.HasItem = ArrayClass.Contains
    ArrayClass.hasItem = ArrayClass.Contains
    ArrayClass.HasValue = ArrayClass.Contains
    ArrayClass.hasValue = ArrayClass.Contains

    function ArrayClass:OfType(...)
        return self:_AddConstraint("OfType", function(SelfRef, TargetArray, SubType)
            for Index, Value in ipairs(TargetArray) do
                local Success, SubMessage = SubType:Check(Value)

                if (not Success) then
                    return false, ERR_PREFIX:format((SelfRef._Tags.DenoteParams and PREFIX_PARAM or PREFIX_ARRAY), tostring(Index)) .. SubMessage
                end
            end

            return true, EMPTY_STRING
        end, ...)
    end
    ArrayClass.ofType = ArrayClass.OfType

    function ArrayClass:OfStructure(ArrayToCheck, ...)
        -- Just in case the user does any weird mutation
        local SubTypesCopy = {}

        for Key, Value in ipairs(ArrayToCheck) do
            SubTypesCopy[Key] = Value
        end

        setmetatable(SubTypesCopy, STRUCTURE_TO_FLAT_STR_MT)

        return self:_AddConstraint("OfStructure", function(SelfRef, TargetArray, SubTypesAtPositions)
            -- Check all fields which should be in the object exist (unless optional) and the type check for each passes
            for Index, Checker in ipairs(SubTypesAtPositions) do
                local RespectiveValue = TargetArray[Index]

                if (RespectiveValue == nil and not Checker._Tags.Optional) then
                    return false, self:_PrefixError(ERR_INDEX_NIL, tostring(Index))
                end

                local Success, SubMessage = Checker:Check(RespectiveValue)

                if (not Success) then
                    return false, self:_PrefixError(ERR_PREFIX, tostring(Index)) .. SubMessage
                end
            end

            -- Check there are no extra indexes which shouldn't be in the object
            if (SelfRef._Tags.Strict) then
                for Index in ipairs(TargetArray) do
                    local Checker = SubTypesAtPositions[Index]

                    if (not Checker) then
                        return false, self:_PrefixError(ERR_UNEXPECTED_VALUE, tostring(Index))
                    end
                end
            end

            return true, EMPTY_STRING
        end, SubTypesCopy, ...)
    end
    ArrayClass.ofStructure = ArrayClass.OfStructure

    function ArrayClass:StructuralEquals(Other)
        return self:OfStructure(Other):Strict()
    end
    ArrayClass.structuralEquals = ArrayClass.StructuralEquals

    function ArrayClass:Strict()
        return self:AddTag("Strict")
    end
    ArrayClass.strict = ArrayClass.Strict

    function ArrayClass:DenoteParams()
        return self:AddTag("DenoteParams")
    end
    ArrayClass.denoteParams = ArrayClass.DenoteParams

    ArrayClass.Equals = Equals
    ArrayClass.equals = Equals
    ArrayClass.IsAValueIn = IsAValueIn
    ArrayClass.isAValueIn = IsAValueIn
    ArrayClass.IsAKeyIn = IsAKeyIn
    ArrayClass.isAKeyIn = IsAKeyIn
    ArrayClass.ValueOf = IsAValueIn
    ArrayClass.valueOf = IsAValueIn
    ArrayClass.KeyOf = IsAKeyIn
    ArrayClass.keyOf = IsAKeyIn

    Types.Array = Array
end




do
    type ObjectTypeCheckerObject = TypeCheckerObject & {
        OfStructure: ObjectTypeCheckerObject;
        ofStructure: ObjectTypeCheckerObject;

        Strict: ObjectTypeCheckerObject;
        strict: ObjectTypeCheckerObject;

        Equals: ObjectTypeCheckerObject;
        equals: ObjectTypeCheckerObject;

        IsAValueIn: ObjectTypeCheckerObject;
        isAValueIn: ObjectTypeCheckerObject;

        IsAKeyIn: ObjectTypeCheckerObject;
        isAKeyIn: ObjectTypeCheckerObject;

        ValueOf: ObjectTypeCheckerObject;
        valueOf: ObjectTypeCheckerObject;

        KeyOf: ObjectTypeCheckerObject;
        keyOf: ObjectTypeCheckerObject;

        OfValueType: ObjectTypeCheckerObject;
        ofValueType: ObjectTypeCheckerObject;

        OfKeyType: ObjectTypeCheckerObject;
        ofKeyType: ObjectTypeCheckerObject;
    }

    local Object: TypeCreatorFunction<ObjectTypeCheckerObject>, ObjectClass = Types.Template("Object")

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

    function ObjectClass:OfStructure(OriginalSubTypes)
        -- Just in case the user does any weird mutation
        local SubTypesCopy = {}

        for Key, Value in pairs(OriginalSubTypes) do
            SubTypesCopy[Key] = Value
        end

        setmetatable(SubTypesCopy, STRUCTURE_TO_FLAT_STR_MT)

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

    function ObjectClass:OfValueType(...)
        return self:_AddConstraint("OfValueType", function(_, TargetArray, SubType)
            for Index, Value in pairs(TargetArray) do
                local Success, SubMessage = SubType:Check(Value)

                if (not Success) then
                    return false, "[OfValueType: Key '" .. tostring(Index) .. "'] " .. SubMessage
                end
            end

            return true, EMPTY_STRING
        end, ...)
    end
    ObjectClass.ofValueType = ObjectClass.OfValueType

    function ObjectClass:OfKeyType(...)
        return self:_AddConstraint("OfKeyType", function(_, TargetArray, SubType)
            for Index, Value in pairs(TargetArray) do
                local Success, SubMessage = SubType:Check(Value)

                if (not Success) then
                    return false, "[OfKeyType: Key '" .. tostring(Index) .. "'] " .. SubMessage
                end
            end

            return true, EMPTY_STRING
        end, ...)
    end
    ObjectClass.ofKeyType = ObjectClass.OfKeyType

    function ObjectClass:Strict()
        return self:AddTag("Strict")
    end
    ObjectClass.strict = ObjectClass.Strict

    ObjectClass.Equals = Equals
    ObjectClass.equals = Equals
    ObjectClass.IsAValueIn = IsAValueIn
    ObjectClass.isAValueIn = IsAValueIn
    ObjectClass.IsAKeyIn = IsAKeyIn
    ObjectClass.isAKeyIn = IsAKeyIn
    ObjectClass.ValueOf = IsAValueIn
    ObjectClass.valueOf = IsAValueIn
    ObjectClass.KeyOf = IsAKeyIn
    ObjectClass.keyOf = IsAKeyIn

    ObjectClass._InitialConstraint = ObjectClass.OfStructure

    Types.Object = Object
end




do
    type InstanceTypeCheckerObject = TypeCheckerObject & {
        OfStructure: InstanceTypeCheckerObject;
        ofStructure: InstanceTypeCheckerObject;

        IsA: InstanceTypeCheckerObject;
        isA: InstanceTypeCheckerObject;

        CheckProperty: InstanceTypeCheckerObject;
        checkProperty: InstanceTypeCheckerObject;

        Strict: InstanceTypeCheckerObject;
        strict: InstanceTypeCheckerObject;

        Equals: InstanceTypeCheckerObject;
        equals: InstanceTypeCheckerObject;

        IsAValueIn: InstanceTypeCheckerObject;
        isAValueIn: InstanceTypeCheckerObject;

        IsAKeyIn: InstanceTypeCheckerObject;
        isAKeyIn: InstanceTypeCheckerObject;

        ValueOf: InstanceTypeCheckerObject;
        valueOf: InstanceTypeCheckerObject;

        KeyOf: InstanceTypeCheckerObject;
        keyOf: InstanceTypeCheckerObject;
    }

    local InstanceChecker: TypeCreatorFunction<InstanceTypeCheckerObject>, InstanceCheckerClass = Types.Template("Instance")

    function InstanceCheckerClass:_Initial(TargetObject)
        if (typeof(TargetObject) ~= "Instance") then
            return false, "Expected Instance, got " .. typeof(TargetObject)
        end

        return true, EMPTY_STRING
    end

    function InstanceCheckerClass:OfStructure(OriginalSubTypes)
        -- Just in case the user does any weird mutation
        local SubTypesCopy = {}

        for Key, Value in pairs(OriginalSubTypes) do
            SubTypesCopy[Key] = Value
        end

        setmetatable(SubTypesCopy, STRUCTURE_TO_FLAT_STR_MT)

        return self:_AddConstraint("OfStructure", function(SelfRef, InstanceRoot, SubTypes)
            -- Check all fields which should be in the object exist (unless optional) and the type check for each passes
            for Key, Checker in pairs(SubTypes) do
                local RespectiveValue = InstanceRoot:FindFirstChild(Key)

                --[[ if (RespectiveValue == nil and not Checker._Tags.Optional) then
                    return false, "[Instance '" .. tostring(Key) .. "'] is nil"
                end ]]

                local Success, SubMessage = Checker:Check(RespectiveValue)

                if (not Success) then
                    return false, "[Instance '" .. tostring(Key) .. "'] " .. SubMessage
                end
            end

            -- Check there are no extra fields which shouldn't be in the object
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

    function InstanceCheckerClass:IsA(...)
        return self:_AddConstraint("IsA", function(_, InstanceRoot, InstanceIsA)
            if (not InstanceRoot:IsA(InstanceIsA)) then
                return false, "Expected " .. InstanceIsA .. ", got " .. InstanceRoot.ClassName
            end

            return true, EMPTY_STRING
        end, ...)
    end
    InstanceCheckerClass.isA = InstanceCheckerClass.IsA

    function InstanceCheckerClass:CheckProperty(...)
        return self:_AddConstraint("CheckProperty", function(_, InstanceRoot, PropertyName, Checker)
            return Checker:Check(InstanceRoot[PropertyName])
        end, ...)
    end
    InstanceCheckerClass.checkProperty = InstanceCheckerClass.CheckProperty

    function InstanceCheckerClass:Strict()
        return self:AddTag("Strict")
    end
    InstanceCheckerClass.strict = InstanceCheckerClass.Strict

    -- TODO: CheckProperties

    InstanceCheckerClass.Equals = Equals
    InstanceCheckerClass.equals = Equals
    InstanceCheckerClass.IsAValueIn = IsAValueIn
    InstanceCheckerClass.isAValueIn = IsAValueIn
    InstanceCheckerClass.IsAKeyIn = IsAKeyIn
    InstanceCheckerClass.isAKeyIn = IsAKeyIn
    InstanceCheckerClass.ValueOf = IsAValueIn
    InstanceCheckerClass.valueOf = IsAValueIn
    InstanceCheckerClass.KeyOf = IsAKeyIn
    InstanceCheckerClass.keyOf = IsAKeyIn

    InstanceCheckerClass._InitialConstraint = InstanceCheckerClass.IsA

    Types.Instance = InstanceChecker
end




do
    type BooleanTypeCheckerObject = TypeCheckerObject & {
        Equals: BooleanTypeCheckerObject;
        equals: BooleanTypeCheckerObject;

        IsAValueIn: BooleanTypeCheckerObject;
        isAValueIn: BooleanTypeCheckerObject;

        IsAKeyIn: BooleanTypeCheckerObject;
        isAKeyIn: BooleanTypeCheckerObject;

        ValueOf: BooleanTypeCheckerObject;
        valueOf: BooleanTypeCheckerObject;

        KeyOf: BooleanTypeCheckerObject;
        keyOf: BooleanTypeCheckerObject;
    }

    local Boolean: TypeCreatorFunction<BooleanTypeCheckerObject>, BooleanClass = Types.Template("Boolean")

    function BooleanClass:_Initial(TargetBoolean)
        if (typeof(TargetBoolean) ~= "boolean") then
            return false, "Expected boolean, got " .. typeof(TargetBoolean)
        end

        return true, EMPTY_STRING
    end

    BooleanClass.Equals = Equals
    BooleanClass.equals = Equals
    BooleanClass.IsAValueIn = IsAValueIn
    BooleanClass.isAValueIn = IsAValueIn
    BooleanClass.IsAKeyIn = IsAKeyIn
    BooleanClass.isAKeyIn = IsAKeyIn
    BooleanClass.ValueOf = IsAValueIn
    BooleanClass.valueOf = IsAValueIn
    BooleanClass.KeyOf = IsAKeyIn
    BooleanClass.keyOf = IsAKeyIn

    BooleanClass._InitialConstraint = BooleanClass.Equals

    Types.Boolean = Boolean
    Types.boolean = Boolean
end




do
    local EnumChecker, EnumCheckerClass = Types.Template("Enum")

    function EnumCheckerClass:_Initial(Value)
        local GotType = typeof(Value)

        if (GotType ~= "EnumItem" and GotType ~= "Enum") then
            return false, "Expected string, got " .. GotType
        end

        return true, EMPTY_STRING
    end

    function EnumCheckerClass:IsA(...)
        return self:_AddConstraint("IsA", function(_, Value, TargetEnum)
            local PassedType = typeof(Value)
            local TargetType = typeof(TargetEnum)

            -- Both are EnumItems
            if (PassedType == "EnumItem" and TargetType == "EnumItem") then
                return Value == TargetEnum, "Expected " .. tostring(TargetEnum) .. ", got " .. tostring(Value)
            elseif (PassedType == "EnumItem" and TargetType == "Enum") then
                return table.find(TargetEnum:GetEnumItems(), Value) ~= nil, "Expected a " .. tostring(TargetEnum) .. ", got " .. tostring(Value)
            end

            return false, "Invalid comparison: " .. PassedType .. " to " .. TargetType
        end, ...)
    end
    EnumCheckerClass.isA = EnumCheckerClass.IsA

    EnumCheckerClass.Equals = Equals
    EnumCheckerClass.equals = Equals
    EnumCheckerClass.IsAValueIn = IsAValueIn
    EnumCheckerClass.isAValueIn = IsAValueIn
    EnumCheckerClass.IsAKeyIn = IsAKeyIn
    EnumCheckerClass.isAKeyIn = IsAKeyIn
    EnumCheckerClass.ValueOf = IsAValueIn
    EnumCheckerClass.valueOf = IsAValueIn
    EnumCheckerClass.KeyOf = IsAKeyIn
    EnumCheckerClass.keyOf = IsAKeyIn
    EnumCheckerClass._InitialConstraint = EnumCheckerClass.IsA

    Types.Enum = EnumChecker
end




do
    type NilTypeCheckerObject = TypeCheckerObject & {}

    local NilChecker: TypeCreatorFunction<NilTypeCheckerObject>, NilCheckerClass = Types.Template("Nil")

    function NilCheckerClass:_Initial(Value)
        if (Value == nil) then
            return false, "Expected nil, got " .. typeof(Value)
        end

        return true, EMPTY_STRING
    end

    Types.Nil = NilChecker
end




Types.Axes = Types.FromTypeName("Axes")
Types.BrickColor = Types.FromTypeName("BrickColor")
Types.CatalogSearchParams = Types.FromTypeName("CatalogSearchParams")
Types.CFrame = Types.FromTypeName("CFrame")
Types.Color3 = Types.FromTypeName("Color3")
Types.ColorSequence = Types.FromTypeName("ColorSequence")
Types.ColorSequenceKeypoint = Types.FromTypeName("ColorSequenceKeypoint")
Types.DateTime = Types.FromTypeName("DateTime")
Types.DockWidgetPluginGuiInfo = Types.FromTypeName("DockWidgetPluginGuiInfo")
Types.Enums = Types.FromTypeName("Enums")
Types.Faces = Types.FromTypeName("Faces")
Types.FloatCurveKey = Types.FromTypeName("FloatCurveKey")
Types.NumberRange = Types.FromTypeName("NumberRange")
Types.NumberSequence = Types.FromTypeName("NumberSequence")
Types.NumberSequenceKeypoint = Types.FromTypeName("NumberSequenceKeypoint")
Types.OverlapParams = Types.FromTypeName("OverlapParams")
Types.PathWaypoint = Types.FromTypeName("PathWaypoint")
Types.PhysicalProperties = Types.FromTypeName("PhysicalProperties")
Types.Random = Types.FromTypeName("Random")
Types.Ray = Types.FromTypeName("Ray")
Types.RaycastParams = Types.FromTypeName("RaycastParams")
Types.RaycastResult = Types.FromTypeName("RaycastResult")
Types.RBXScriptConnection = Types.FromTypeName("RBXScriptConnection")
Types.RBXScriptSignal = Types.FromTypeName("RBXScriptSignal")
Types.Rect = Types.FromTypeName("Rect")
Types.Region3 = Types.FromTypeName("Region3")
Types.Region3int16 = Types.FromTypeName("Region3int16")
Types.TweenInfo = Types.FromTypeName("TweenInfo")
Types.UDim = Types.FromTypeName("UDim")
Types.UDim2 = Types.FromTypeName("UDim2")
Types.Vector2 = Types.FromTypeName("Vector2")
Types.Vector2int16 = Types.FromTypeName("Vector2int16")
Types.Vector3 = Types.FromTypeName("Vector3")
Types.Vector3int16 = Types.FromTypeName("Vector3int16")

--- Creates a function which checks params as if they were a strict Array checker
function Types.Params(...)
    local Params = {...}

    for _, ParamChecker in ipairs(Params) do
        Types._AssertIsTypeBase(ParamChecker)
    end

    local Checker = Types.Array():StructuralEquals(Params):DenoteParams()

    return function(...)
        Checker:Assert({...})
    end
end
Types.params = Types.Params

--- Creates a function which checks variadic params against a single given type checker
function Types.VariadicParams(CompareType)
    Types._AssertIsTypeBase(CompareType)

    local Checker = Types.Array():OfType(CompareType):DenoteParams()

    return function(...)
        Checker:Assert({...})
    end
end
Types.variadicParams = Types.VariadicParams

return Types