local Template = require(script.Parent:WaitForChild("_Template"))
    type TypeCheckerConstructor<T, P...> = Template.TypeCheckerConstructor<T, P...>
    type TypeChecker<ExtensionClass, Primitive> = Template.TypeChecker<ExtensionClass, Primitive>

type AnyTypeChecker = TypeChecker<AnyTypeChecker, any>
local AnyChecker: TypeCheckerConstructor<AnyTypeChecker>, AnyCheckerClass = Template.Create("Any")

function AnyCheckerClass._Initial(Item)
    if (Item == nil) then
        return false, "Expected something, got nil"
    end

    return true
end

return AnyChecker