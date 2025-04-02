--!native
--!optimize 2

if (not script and Instance) then
    script = game:GetService("ReplicatedFirst").TypeGuard.Roblox.UDim
end

local Template = require(script.Parent.Parent._Template)
    type TypeCheckerConstructor<T, P...> = Template.TypeCheckerConstructor<T, P...>
    type TypeChecker<ExtensionClass, Primitive> = Template.TypeChecker<ExtensionClass, Primitive>

type UDimTypeChecker = TypeChecker<UDimTypeChecker, UDim> & {

};

local Core = script.Parent.Parent.Core
    local Number = require(Core.Number)
        local DynamicInt32 = Number():Integer(32, true):Dynamic()
        local Float32 = Number():Float(32)
    local Object = require(Core.Object)

local Checker = Object({
    Offset = DynamicInt32;
    Scale = Float32;
}):Unmap(function(Value)
    return UDim.new(Value.Scale, Value.Offset)
end):Strict():NoConstraints()

Checker = Checker:Modify({
    Name = "UDim";
    _TypeOf = {"UDim"};
})

table.freeze(Checker)

return function()
    return Checker
end :: TypeCheckerConstructor<UDimTypeChecker>