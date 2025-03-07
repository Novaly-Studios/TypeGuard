--!native
--!optimize 2

if (not script) then
    script = game:GetService("ReplicatedFirst").TypeGuard.Roblox.Content
end

local Template = require(script.Parent.Parent._Template)
    type TypeCheckerConstructor<T, P...> = Template.TypeCheckerConstructor<T, P...>
    type FunctionalArg<T> = Template.FunctionalArg<T>
    type TypeChecker<ExtensionClass, Primitive> = Template.TypeChecker<ExtensionClass, Primitive>
    type SelfReturn<T, P...> = Template.SelfReturn<T, P...>

type ContentTypeChecker = TypeChecker<ContentTypeChecker, Content> & {

};

local Core = script.Parent.Parent.Core
    local Optional = require(Core.Optional)
    local String = require(Core.String)
        local DefaultString = String()
    local Object = require(Core.Object)

local RbxEnum = require(script.Parent.Enum)
    local EnumContentSourceType = RbxEnum(Enum.ContentSourceType)

local Checker = Object({
    SourceType = EnumContentSourceType;
    Uri = Optional(DefaultString);
    -- No 'Object' support yet.
}):Unmap(function(Value)
    return Content.fromUri(Value.Uri)
end):Strict():NoConstraints()
Checker.Type = "Content"
Checker._TypeOf = {Checker.Type}

return function()
    return Checker
end :: TypeCheckerConstructor<ContentTypeChecker>