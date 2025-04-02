--!native
--!optimize 2

if (not script and Instance) then
    script = game:GetService("ReplicatedFirst").TypeGuard.Roblox.Font
end

local Template = require(script.Parent.Parent._Template)
    type TypeCheckerConstructor<T, P...> = Template.TypeCheckerConstructor<T, P...>
    type FunctionalArg<T> = Template.FunctionalArg<T>
    type TypeChecker<ExtensionClass, Primitive> = Template.TypeChecker<ExtensionClass, Primitive>

type FontTypeChecker = TypeChecker<FontTypeChecker, Font> & {

};

local Core = script.Parent.Parent.Core
    local Cacheable = require(Core.Cacheable)
    local Boolean = require(Core.Boolean)
        local DefaultBoolean = Boolean()
    local Object = require(Core.Object)
    local String = require(Core.String)
        local CacheableString = Cacheable(String())

local RbxEnum = require(script.Parent.Enum)
    local EnumFontWeight = RbxEnum(Enum.FontWeight)
    local EnumFontStyle = RbxEnum(Enum.FontStyle)

local Checker = Object({
    Weight = EnumFontWeight;
    Family = CacheableString;
    Style = EnumFontStyle;
    Bold = DefaultBoolean;
}):Unmap(function(Value)
    local Result = Font.new(Value.Family, Value.Weight, Value.Style)
    Result.Bold = Value.Bold
    return Result
end):Strict():NoConstraints()

Checker = Checker:Modify({
    Name = "Font";
    _TypeOf = {"Font"};
})

table.freeze(Checker)

return function()
    return Checker
end :: TypeCheckerConstructor<FontTypeChecker>