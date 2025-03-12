--!native
--!optimize 2

if (not script) then
    script = game:GetService("ReplicatedFirst").TypeGuard.Roblox.Ray
end

local Template = require(script.Parent.Parent._Template)
    type TypeCheckerConstructor<T, P...> = Template.TypeCheckerConstructor<T, P...>
    type FunctionalArg<T> = Template.FunctionalArg<T>
    type TypeChecker<ExtensionClass, Primitive> = Template.TypeChecker<ExtensionClass, Primitive>

type RaycastParamsTypeChecker = TypeChecker<RaycastParamsTypeChecker, RaycastParams> & {

};

local Core = script.Parent.Parent.Core
    local Boolean = require(Core.Boolean)
        local DefaultBoolean = Boolean()
    local Object = require(Core.Object)
    local String = require(Core.String)
        local DefaultString = String()
    local Array = require(Core.Array)

local RbxEnum = require(script.Parent.Enum)
    local EnumRaycastFilterType = RbxEnum(Enum.RaycastFilterType)

local RbxInstance = require(script.Parent.Instance)

local Checker = Object({
    FilterDescendantsInstances = Array(RbxInstance);
    BruteForceAllSlow = DefaultBoolean;
    RespectCanCollide = DefaultBoolean;
    CollisionGroup = DefaultString;
    IgnoreWater = DefaultBoolean;
    FilterType = EnumRaycastFilterType;
}):Unmap(function(Value)
    local Result = RaycastParams.new()

    for Key, Value in Value do
        Result[Key] = Value
    end

    return Result
end):Strict():NoConstraints()
--[[ Checker.Type = "RaycastParams"
Checker._TypeOf = {Checker.Type} ]]

Checker = Checker:Modify({
    Type = "RaycastParams";
    _TypeOf = {"RaycastParams"};
})

return function()
    return Checker
end :: TypeCheckerConstructor<RaycastParamsTypeChecker>