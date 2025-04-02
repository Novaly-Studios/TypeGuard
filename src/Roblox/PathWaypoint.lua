--!native
--!optimize 2

if (not script and Instance) then
    script = game:GetService("ReplicatedFirst").TypeGuard.Roblox.Ray
end

local Template = require(script.Parent.Parent._Template)
    type TypeCheckerConstructor<T, P...> = Template.TypeCheckerConstructor<T, P...>
    type FunctionalArg<T> = Template.FunctionalArg<T>
    type TypeChecker<ExtensionClass, Primitive> = Template.TypeChecker<ExtensionClass, Primitive>

type PathWaypointTypeChecker = TypeChecker<PathWaypointTypeChecker, PathWaypoint> & {

};

local Core = script.Parent.Parent.Core
    local Cacheable = require(Core.Cacheable)
    local Object = require(Core.Object)
    local String = require(Core.String)
        local CacheableString = Cacheable(String())

local RbxEnum = require(script.Parent.Enum)
    local EnumPathWaypointAction = RbxEnum(Enum.PathWaypointAction)

local RbxVector3 = require(script.Parent.Vector3)
    local DefaultVector3 = RbxVector3()

local Checker = Object({
    Position = DefaultVector3;
    Action = EnumPathWaypointAction;
    Label = CacheableString;
}):Unmap(function(Value)
    return PathWaypoint.new(Value.Position, Value.Action, Value.Label)
end):Strict():NoConstraints()

Checker = Checker:Modify({
    Name = "PathWaypoint";
    _TypeOf = {"PathWaypoint"};
})

table.freeze(Checker)

return function()
    return Checker
end :: TypeCheckerConstructor<PathWaypointTypeChecker>