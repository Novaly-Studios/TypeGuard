--!native
--!optimize 2

if (not script) then
    script = game:GetService("ReplicatedFirst").TypeGuard.Core.Nil
end

local Template = require(script.Parent.Parent._Template)
    type TypeCheckerConstructor<T, P...> = Template.TypeCheckerConstructor<T, P...>
    type TypeChecker<ExtensionClass, Primitive> = Template.TypeChecker<ExtensionClass, Primitive>
    type SelfReturn<T, P...> = Template.SelfReturn<T, P...>

local Util = require(script.Parent.Parent.Util)
    local CreateStandardInitial = Util.CreateStandardInitial

type UserdataTypeChecker = TypeChecker<UserdataTypeChecker, typeof(newproxy(true))> & {

};

local UserdataChecker: (() -> (UserdataTypeChecker)), UserdataCheckerClass = Template.Create("Userdata")
UserdataCheckerClass._Initial = CreateStandardInitial("userdata")
UserdataCheckerClass._TypeOf = {"userdata"}
return UserdataChecker