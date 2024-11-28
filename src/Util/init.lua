-- These are only used to validate inputs to TypeChecker constraints & methods. Not in Check() runtime.
local Expect = {
    ENUM_OR_ENUM_ITEM_OR_FUNCTION = {"Enum", "EnumItem", "function"};
    INSTANCE_OR_FUNCTION = {"Instance", "function"};
    BOOLEAN_OR_FUNCTION = {"boolean", "function"};
    STRING_OR_FUNCTION = {"string", "function"};
    NUMBER_OR_FUNCTION = {"number", "function"};
    TABLE_OR_FUNCTION = {"table", "function"};
    FUNCTION_OR_NIL = {"function", "nil"};
    SOMETHING = {"something"};
    FUNCTION = {"function"};
    BOOLEAN = {"boolean"};
    NUMBER = {"number"};
    STRING = {"string"};
    TABLE = {"table"};
}

--- The '_Initial' part of a TypeChecker simply checks the type. This is for basic Luau types.
local function CreateStandardInitial(ExpectedTypeName: string): ((...any) -> (boolean, string?))
    return function(_, Item)
        local ItemType = typeof(Item)

        if (ItemType == ExpectedTypeName) then
            return true
        end

        return false, `Expected {ExpectedTypeName}, got {ItemType}`
    end
end

--- This is only really for type checking internally for data passed to constraints and util functions.
local function ExpectType(Target: any, ExpectedTypes: {string}, ArgKey: number | string)
    local GotType = typeof(Target)

    for _, PossibleType in ExpectedTypes do
        if ((GotType == PossibleType) or (GotType ~= nil and PossibleType == "something")) then
            return
        end
    end

    error((`Invalid argument #{ArgKey} ({table.concat(ExpectedTypes, " or ")} expected, got {GotType})`), 2)
end

--- table.concat except it uses tostring on all values.
local function ConcatWithToString(Array: {any}, Separator: string): string
    local Result = ""

    for _, Value in Array do
        Result ..= tostring(Value) .. Separator
    end

    return (Result == "" and Result or Result:sub(1, #Result - #Separator))
end

--- Checks if an object contains the fields which define a TypeChecker from this library.
function AssertIsTypeBase(Subject: any, Position: number | string)
    ExpectType(Subject, Expect.TABLE, Position)
    assert(Subject._TC, "Subject is not a TypeChecker.")
end

-- Helps printing out the simplified structure of constraints and the contents of tables which do not satisfy some constraints.
local STRUCTURE_STRING_MT = {
    __tostring = function(self)
        local Pairings = {}

        for Key, Value in self do
            table.insert(Pairings, tostring(Key) .. " = " .. tostring(Value))
        end

        return "{" .. ConcatWithToString(Pairings, ", ") .. "}"
    end;
}

return {
    ByteSerializer = require(script.ByteSerializer);
    BitSerializer = require(script.BitSerializer);

    CreateStandardInitial = CreateStandardInitial;
    ConcatWithToString = ConcatWithToString;
    AssertIsTypeBase = AssertIsTypeBase;
    ExpectType = ExpectType;

    StructureStringMT = STRUCTURE_STRING_MT;

    Expect = Expect;
}