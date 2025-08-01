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
local function AssertIsTypeBase(Subject: any, Position: number | string)
    ExpectType(Subject, Expect.TABLE, Position)
    assert(Subject._TC, "Subject is not a TypeChecker")
end

--- Creates a string of formatted binary data of a buffer. For debugging.
local function BufferToBinary(In: buffer, Reverse: boolean?): string
    local Temp = buffer.create(1)

    return buffer.tostring(In):gsub(".", function(Char)
        buffer.writeu8(Temp, 0, Char:byte())

        if (Reverse) then
            return `{buffer.readbits(Temp, 0, 1)}{buffer.readbits(Temp, 1, 1)}{buffer.readbits(Temp, 2, 1)}{buffer.readbits(Temp, 3, 1)}{buffer.readbits(Temp, 4, 1)}{buffer.readbits(Temp, 5, 1)}{buffer.readbits(Temp, 6, 1)}{buffer.readbits(Temp, 7, 1)}/{Char:byte()} `
        end

        return `0b{buffer.readbits(Temp, 7, 1)}{buffer.readbits(Temp, 6, 1)}{buffer.readbits(Temp, 5, 1)}{buffer.readbits(Temp, 4, 1)}{buffer.readbits(Temp, 3, 1)}{buffer.readbits(Temp, 2, 1)}{buffer.readbits(Temp, 1, 1)}{buffer.readbits(Temp, 0, 1)}/{Char:byte()} `
    end), buffer.len(In)
end

-- Helps printing out the simplified structure of constraints and the contents of tables which do not satisfy some constraints.
local STRUCTURE_STRING_MT = table.freeze({
    __tostring = function(self)
        local Pairings = {}

        for Key, Value in self do
            table.insert(Pairings, tostring(Key) .. " = " .. tostring(Value))
        end

        return "{" .. ConcatWithToString(Pairings, ", ") .. "}"
    end;
})

local Serializers = require(script.Serializers)
export type Serializer = Serializers.Serializer

return table.freeze({
    Serializers = Serializers;
    
    CreateStandardInitial = CreateStandardInitial;
    ConcatWithToString = ConcatWithToString;
    AssertIsTypeBase = AssertIsTypeBase;
    BufferToBinary = BufferToBinary;
    ExpectType = ExpectType;

    StructureStringMT = STRUCTURE_STRING_MT;

    Expect = Expect;
})