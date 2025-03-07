--!native
--!optimize 2

if (not script) then
    script = game:GetService("ReplicatedFirst").TypeGuard.Roblox.Region3
end

local Template = require(script.Parent.Parent._Template)
    type TypeCheckerConstructor<T, P...> = Template.TypeCheckerConstructor<T, P...>
    type FunctionalArg<T> = Template.FunctionalArg<T>
    type TypeChecker<ExtensionClass, Primitive> = Template.TypeChecker<ExtensionClass, Primitive>
    type SelfReturn<T, P...> = Template.SelfReturn<T, P...>

type Region3TypeChecker = TypeChecker<Region3TypeChecker, Region3> & {

};

local Core = script.Parent.Parent.Core
    local Object = require(Core.Object)

local RbxVector3 = require(script.Parent.Vector3)
    local DefaultVector3 = RbxVector3()

local RbxCFrame = require(script.Parent.CFrame)
    local DefaultCFrame = RbxCFrame()

local Checker = Object({
    CFrame = DefaultCFrame;
    Size = DefaultVector3;
}):Unmap(function(Value)
    local Center = Value.CFrame.Position
    local Half = Value.Size / 2
    return Region3.new(Center - Half, Center + Half)
end):Strict():NoConstraints()
Checker.Type = "Region3"
Checker._TypeOf = {Checker.Type}

return function()
    return Checker
end :: TypeCheckerConstructor<Region3TypeChecker>