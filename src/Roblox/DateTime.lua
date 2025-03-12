--!native
--!optimize 2

if (not script) then
    script = game:GetService("ReplicatedFirst").TypeGuard.Roblox.DateTime
end

local Template = require(script.Parent.Parent._Template)
    type TypeCheckerConstructor<T, P...> = Template.TypeCheckerConstructor<T, P...>
    type FunctionalArg<T> = Template.FunctionalArg<T>
    type TypeChecker<ExtensionClass, Primitive> = Template.TypeChecker<ExtensionClass, Primitive>

type DateTimeTypeChecker = TypeChecker<DateTimeTypeChecker, DateTime> & {

};

local Core = script.Parent.Parent.Core
    local Number = require(Core.Number)
        local DefaultNumber = Number()
    local Object = require(Core.Object)

local Checker = Object({
    UnixTimestampMillis = DefaultNumber:NonSerialized();
    UnixTimestamp = DefaultNumber;
}):Unmap(function(Value)
    return DateTime.fromUnixTimestamp(Value.UnixTimestamp)
end):Strict():NoConstraints()
--[[ Checker.Type = "DateTime"
Checker._TypeOf = {Checker.Type} ]]

Checker = Checker:Modify({
    Type = "DateTime";
    _TypeOf = {"DateTime"};
})

return function()
    return Checker
end :: TypeCheckerConstructor<DateTimeTypeChecker>