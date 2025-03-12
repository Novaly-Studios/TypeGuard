--!native
--!optimize 2

if (not script) then
    script = game:GetService("ReplicatedFirst").TypeGuard.Roblox.Ray
end

local Template = require(script.Parent.Parent._Template)
    type TypeCheckerConstructor<T, P...> = Template.TypeCheckerConstructor<T, P...>
    type FunctionalArg<T> = Template.FunctionalArg<T>
    type TypeChecker<ExtensionClass, Primitive> = Template.TypeChecker<ExtensionClass, Primitive>

type OverlapParamsTypeChecker = TypeChecker<OverlapParamsTypeChecker, OverlapParams> & {

};

local Core = script.Parent.Parent.Core
    local Number = require(Core.Number)
        local Int32 = Number():Integer(32)
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
    FilterType = EnumRaycastFilterType;
    MaxParts = Int32;
}):Unmap(function(Value)
    local Result = OverlapParams.new()

    for Key, Value in Value do
        Result[Key] = Value
    end

    return Result
end):Strict():NoConstraints()
--[[ Checker.Type = "OverlapParams"
Checker._TypeOf = {Checker.Type} ]]

Checker = Checker:Modify({
    Type = "OverlapParams";
    _TypeOf = {"OverlapParams"};
})

return function()
    return Checker
end :: TypeCheckerConstructor<OverlapParamsTypeChecker>