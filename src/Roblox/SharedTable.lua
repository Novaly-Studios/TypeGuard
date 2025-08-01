--!native
--!optimize 2

if (not script and Instance) then
    script = game:GetService("ReplicatedFirst").TypeGuard.Roblox.SharedTable
end

local Template = require(script.Parent.Parent._Template)
    type TypeCheckerConstructor<T, P...> = Template.TypeCheckerConstructor<T, P...>
    type FunctionalArg<T> = Template.FunctionalArg<T>
    type TypeChecker<ExtensionClass, Primitive> = Template.TypeChecker<ExtensionClass, Primitive>

local Core = script.Parent.Parent.Core
    local Indexable = require(Core.Indexable)

local TypeOf = {"SharedTable"}

return function(...)
    local Checker = Indexable(...):UnmapStructure(SharedTable.new)
    Checker = Checker:Modify({
        Name = TypeOf[1];
        _TypeOf = TypeOf;
    })
    table.freeze(Checker)
    return Checker
end