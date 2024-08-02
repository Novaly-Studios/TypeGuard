--!native
--!optimize 2

if (not script) then
    script = game:GetService("ReplicatedFirst").TypeGuard.TypeCheckers.Enum
end

local Template = require(script.Parent.Parent:WaitForChild("_Template"))
    type TypeCheckerConstructor<T, P...> = Template.TypeCheckerConstructor<T, P...>
    type FunctionalArg<T> = Template.FunctionalArg<T>
    type TypeChecker<ExtensionClass, Primitive> = Template.TypeChecker<ExtensionClass, Primitive>
    type SelfReturn<T, P...> = Template.SelfReturn<T, P...>

local Util = require(script.Parent.Parent:WaitForChild("Util"))
    local ExpectType = Util.ExpectType
    local Expect = Util.Expect

local Number = require(script.Parent.Parent.Core.Number)

type EnumTypeChecker = TypeChecker<EnumTypeChecker, Enum | EnumItem> & {
    IsA: SelfReturn<EnumTypeChecker, FunctionalArg<Enum | EnumItem>>;
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

--- Ensures that a passed EnumItem is either equivalent to an EnumItem or a sub-item of an Enum class.
function EnumCheckerClass:IsA(TargetEnum)
    ExpectType(TargetEnum, Expect.ENUM_OR_ENUM_ITEM_OR_FUNCTION, 1)

    return self:_AddConstraint(true, "IsA", function(_, Value, TargetEnum)
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
    end, TargetEnum)
end

EnumCheckerClass.InitialConstraint = EnumCheckerClass.IsA

local EnumsList = table.create(3000)
local EnumToID = {}
local Index = 1

for Key, Value in Enum:GetEnums() do
    EnumsList[Index] = Value
    EnumToID[Value] = Index
    Index += 1

    for _, ItemValue in Value:GetEnumItems() do
        EnumsList[Index] = ItemValue
        EnumToID[ItemValue] = Index
        Index += 1
    end
end

local NumberSerializer = Number(1, Index):Integer()
    local NumberDeserialize = NumberSerializer._Deserialize
    local NumberSerialize = NumberSerializer._Serialize

function EnumCheckerClass:_UpdateSerialize()
    local IsA = self:GetConstraint("IsA")

    if (IsA) then
        self._Serialize = function(Buffer, Value, _Cache)
            NumberSerialize(Buffer, EnumToID[Value])
        end
        self._Deserialize = function(Buffer, _Cache)
            return EnumsList[NumberDeserialize(Buffer)]
        end

        return
    end
end

return EnumChecker