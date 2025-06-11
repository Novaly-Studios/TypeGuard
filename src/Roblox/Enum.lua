--!native
--!optimize 2

if (not script and Instance) then
    script = game:GetService("ReplicatedFirst").TypeGuard.Roblox.Enum
end

local Template = require(script.Parent.Parent._Template)
    type TypeCheckerConstructor<T, P...> = Template.TypeCheckerConstructor<T, P...>
    type FunctionalArg<T> = Template.FunctionalArg<T>
    type TypeChecker<ExtensionClass, Primitive> = Template.TypeChecker<ExtensionClass, Primitive>

local Util = require(script.Parent.Parent.Util)
    local ExpectType = Util.ExpectType
    local Expect = Util.Expect

local Core = script.Parent.Parent.Core
    local Cacheable = require(Core.Cacheable)
    local Number = require(Core.Number)
    local String = require(Core.String)

type EnumTypeChecker = TypeChecker<EnumTypeChecker, Enum | EnumItem> & {
    IsA: ((self: EnumTypeChecker, Type: FunctionalArg<Enum | EnumItem>) -> (EnumTypeChecker));
};

local EnumChecker: TypeCheckerConstructor<EnumTypeChecker, FunctionalArg<Enum? | EnumItem?>>, EnumCheckerClass = Template.Create("Enum")
EnumCheckerClass._TypeOf = {"Enum", "EnumItem"}

function EnumCheckerClass:_Initial(Value)
    local GotType = typeof(Value)

    if (GotType == "EnumItem" or GotType == "Enum") then
        return true
    end

    return false, `Expected EnumItem or Enum, got {GotType}`
end

local function _IsA(_, Value, TargetEnum)
    local TargetType = typeof(TargetEnum)

    -- Both are EnumItems.
    if (TargetType == "EnumItem") then
        if (Value == TargetEnum) then
            return true
        end

        return false, `Expected {TargetEnum}, got {Value}`
    end

    -- TargetType is an Enum.
    if (table.find(TargetEnum:GetEnumItems(), Value) == nil) then
        return false, `Expected a {TargetEnum}, got {Value}`
    end

    return true
end

--- Ensures that a passed EnumItem is either equivalent to an EnumItem or a sub-item of an Enum class.
function EnumCheckerClass:IsA(TargetEnum)
    ExpectType(TargetEnum, Expect.ENUM_OR_ENUM_ITEM_OR_FUNCTION, 1)

    return self:_AddConstraint(true, "IsA", _IsA, TargetEnum)
end

EnumCheckerClass.InitialConstraint = EnumCheckerClass.IsA

local EnumClassToIDToEnumItem = {}
local EnumClassToEnumItemToID = {}

for _, EnumClass in Enum:GetEnums() do
    local EnumItemToID = {}
    local IDToEnumItem = {}

    for _, EnumItem in EnumClass:GetEnumItems() do
        local ID = EnumItem.Value
        EnumItemToID[EnumItem] = ID
        IDToEnumItem[ID] = EnumItem
    end

    EnumClassToIDToEnumItem[EnumClass] = IDToEnumItem
    EnumClassToEnumItemToID[EnumClass] = EnumItemToID
end

-- For now, since I can't find any way to find a numerical index for an Enum which won't be re-ordered
-- over time, thus rendered incompatible with Roblox updates. Nasty oof solution.
local EnumSerializer = Cacheable(String())
    local EnumSerializerSerialize = EnumSerializer._Serialize
    local EnumSerializerDeserialize = EnumSerializer._Deserialize

-- On the other hand, this should be forward compatible because EnumItems are deprecated, not removed.
local EnumItemSerializer = Number():Integer(19, true)
    local EnumItemSerializerSerialize = EnumItemSerializer._Serialize
    local EnumItemSerializerDeserialize = EnumItemSerializer._Deserialize

function EnumCheckerClass:_UpdateSerialize()
    local IsA = self:GetConstraint("IsA")
        local IsAValue = IsA and IsA[1]

    if (IsA) then
        -- Enum class is known -> only need to serialize the specific EnumItem.
        if (typeof(IsAValue) == "Enum") then
            return {
                _Serialize = function(Buffer, Value, Context)
                    local BufferContext = Buffer.Context

                    if (BufferContext) then
                        BufferContext("Enum(IsA/Enum)")
                    end

                    EnumItemSerializerSerialize(Buffer, Value.Value, Context)

                    if (BufferContext) then
                        BufferContext()
                    end
                end;
                _Deserialize = function(Buffer, Context)
                    return EnumClassToIDToEnumItem[IsAValue][EnumItemSerializerDeserialize(Buffer)]
                end;
            }
        end

        -- Or it's literally equivalent to an EnumItem -> this doesn't need to store anything.
        return {
            _Serialize = function(Buffer, _Value, _Context)
                local BufferContext = Buffer.Context

                if (BufferContext) then
                    BufferContext("Enum(IsA/EnumItem)")
                    BufferContext()
                end
            end;
            _Deserialize = function(_Buffer, _Context)
                return IsAValue
            end;
        }
    end

    -- No Enum class or EnumItem narrowed down, so it will store a reference to the Enum class (string)
    -- and then a reference to the EnumItem (number).
    return {
        _Serialize = function(Buffer, Value, Context)
            local BufferContext = Buffer.Context

            if (BufferContext) then
                BufferContext("Enum")
            end

            local IsEnumItem = (typeof(Value) == "EnumItem")
            Buffer.WriteUInt(1, (IsEnumItem and 0 or 1)) -- 0 = EnumItem, 1 = Enum
            
            if (IsEnumItem) then
                EnumSerializerSerialize(Buffer, tostring(Value.EnumType), Context)
                EnumItemSerializerSerialize(Buffer, Value.Value, Context)

                if (BufferContext) then
                    BufferContext()
                end

                return
            end

            EnumSerializerSerialize(Buffer, tostring(Value), Context)

            if (BufferContext) then
                BufferContext()
            end
        end;
        _Deserialize = function(Buffer, Context)
            local IsEnumItem = (Buffer.ReadUInt(1) == 0)

            if (IsEnumItem) then
                local EnumType = EnumSerializerDeserialize(Buffer, Context)
                local EnumItem = EnumItemSerializerDeserialize(Buffer)

                -- Maybe we cache each Enum class to GetEnumItems() call above?
                return EnumClassToIDToEnumItem[Enum[EnumType]][EnumItem]
            end

            return Enum[EnumSerializerDeserialize(Buffer, Context)]
        end
    }
end

return EnumChecker