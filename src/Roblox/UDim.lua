--!native
--!optimize 2

if (not script) then
    script = game:GetService("ReplicatedFirst").TypeGuard.Roblox.UDim
end

local Template = require(script.Parent.Parent._Template)
    type TypeCheckerConstructor<T, P...> = Template.TypeCheckerConstructor<T, P...>
    type TypeChecker<ExtensionClass, Primitive> = Template.TypeChecker<ExtensionClass, Primitive>
    type SelfReturn<T, P...> = Template.SelfReturn<T, P...>

type UDimTypeChecker = TypeChecker<UDimTypeChecker, UDim> & {

};

local Core = script.Parent.Parent.Core
    local Number = require(Core.Number)
        local Float32 = Number():Float(32)
        local UInt32 = Number():Integer(32, false)
    local Object = require(Core.Object)

local Checker = Object({
    Offset = UInt32; -- Todo: change to dynamic UInt by default. Add Int(Bits, Unsigned) constraint.
    Scale = Float32;
}):Unmap(function(Value)
    return UDim.new(Value.Scale, Value.Offset)
end):Strict():NoConstraints()
Checker.Type = "UDim"
Checker._TypeOf = {Checker.Type}

return function()
    return Checker
end :: TypeCheckerConstructor<UDimTypeChecker>