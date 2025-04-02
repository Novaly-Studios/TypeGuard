--!native
--!optimize 2

if (not script and Instance) then
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
    UnixTimestamp = DefaultNumber;
}):Unmap(function(Value)
    return DateTime.fromUnixTimestamp(Value.UnixTimestamp)
end):Strict():NoConstraints()

Checker = Checker:Modify({
    Name = "DateTime";
    _TypeOf = {"DateTime"};
})

table.freeze(Checker)

return function()
    return Checker
end :: TypeCheckerConstructor<DateTimeTypeChecker>