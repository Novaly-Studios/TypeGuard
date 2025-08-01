--!native
--!optimize 2

if (not script and Instance) then
    script = game:GetService("ReplicatedFirst").TypeGuard.Roblox.Content
end

local Template = require(script.Parent.Parent._Template)
    type TypeCheckerConstructor<T, P...> = Template.TypeCheckerConstructor<T, P...>
    type FunctionalArg<T> = Template.FunctionalArg<T>
    type TypeChecker<ExtensionClass, Primitive> = Template.TypeChecker<ExtensionClass, Primitive>

type ContentTypeChecker = TypeChecker<ContentTypeChecker, Content> & {

};

local Core = script.Parent.Parent.Core
    local Indexable = require(Core.Indexable)
    local Cacheable = require(Core.Cacheable)
    local Optional = require(Core.Optional)
    local String = require(Core.String)
        local CacheableString = Cacheable(String())

local RbxInstance = require(script.Parent.Instance)
    local CacheableInstance = Cacheable(RbxInstance())

local Checker = Indexable({
    Object = Optional(CacheableInstance);
    Uri = Optional(CacheableString);
}):Unmap(function(Value)
    local Object = Value.Object
    if (Object) then
        return Content.fromObject(Object)
    end

    local Uri = Value.Uri
    if (Uri) then
        return Content.fromUri(Uri)
    end

    return Content.none
end):Strict():NoConstraints()

Checker = Checker:Modify({
    Name = "Content";
    _TypeOf = {"Content"};
})

table.freeze(Checker)

return function()
    return Checker
end :: TypeCheckerConstructor<ContentTypeChecker>