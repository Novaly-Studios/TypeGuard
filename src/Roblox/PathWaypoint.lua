--!native
--!optimize 2

if (not script) then
    script = game:GetService("ReplicatedFirst").TypeGuard.Roblox.Ray
end

local Template = require(script.Parent.Parent._Template)
    type TypeCheckerConstructor<T, P...> = Template.TypeCheckerConstructor<T, P...>
    type FunctionalArg<T> = Template.FunctionalArg<T>
    type TypeChecker<ExtensionClass, Primitive> = Template.TypeChecker<ExtensionClass, Primitive>
    type SelfReturn<T, P...> = Template.SelfReturn<T, P...>

type PathWaypointTypeChecker = TypeChecker<PathWaypointTypeChecker, PathWaypoint> & {

};

local Core = script.Parent.Parent.Core
    local Object = require(Core.Object)
    local String = require(Core.String)
        local DefaultString = String()

local RbxEnum = require(script.Parent.Enum)
    local EnumPathWaypointAction = RbxEnum(Enum.PathWaypointAction)

local RbxVector3 = require(script.Parent.Vector3)
    local DefaultVector3 = RbxVector3()

local Checker = Object({
    Position = DefaultVector3;
    Action = EnumPathWaypointAction;
    Label = DefaultString;
}):Unmap(function(Value)
    return PathWaypoint.new(Value.Position, Value.Action, Value.Label)
end):Strict():NoConstraints()
Checker.Type = "PathWaypoint"
Checker._TypeOf = {Checker.Type}

return function()
    return Checker
end :: TypeCheckerConstructor<PathWaypointTypeChecker>