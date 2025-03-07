--!native
--!optimize 2

if (not script) then
    script = game:GetService("ReplicatedFirst").TypeGuard.Roblox.SharedTable
end

local Template = require(script.Parent.Parent._Template)
    type TypeCheckerConstructor<T, P...> = Template.TypeCheckerConstructor<T, P...>
    type FunctionalArg<T> = Template.FunctionalArg<T>
    type TypeChecker<ExtensionClass, Primitive> = Template.TypeChecker<ExtensionClass, Primitive>
    type SelfReturn<T, P...> = Template.SelfReturn<T, P...>

local Core = script.Parent.Parent.Core
    local Object = require(Core.Object)

local TypeOf = {"SharedTable"}

return function(...)
    local Checker = Object(...):UnmapStructure(function(Value)
        return SharedTable.new(Value)
    end)
    Checker.Type = TypeOf[1]
    Checker._TypeOf = TypeOf
    return Checker
end