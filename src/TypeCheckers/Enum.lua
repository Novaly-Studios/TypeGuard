local Template = require(script.Parent:WaitForChild("_Template"))
    type TypeCheckerConstructor<T, P...> = Template.TypeCheckerConstructor<T, P...>
    type TypeChecker<ExtensionClass, Primitive> = Template.TypeChecker<ExtensionClass, Primitive>
    type SelfReturn<T, P...> = Template.SelfReturn<T, P...>

local Util = require(script.Parent.Parent:WaitForChild("Util"))
    local ExpectType = Util.ExpectType
    local Expect = Util.Expect

type EnumTypeChecker = TypeChecker<EnumTypeChecker, Enum | EnumItem> & {
    IsA: SelfReturn<EnumTypeChecker, Enum | EnumItem | (any?) -> Enum | EnumItem>;
};

local EnumChecker: TypeCheckerConstructor<EnumTypeChecker, Enum? | EnumItem? | (any?) -> (Enum | EnumItem)?>, EnumCheckerClass = Template.Create("Enum")

function EnumCheckerClass._Initial(Value)
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

return EnumChecker