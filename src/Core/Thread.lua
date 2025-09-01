--!native
--!optimize 2

if (not script and Instance) then
    script = game:GetService("ReplicatedFirst").TypeGuard.Core.Thread
end

local Template = require(script.Parent.Parent._Template)
    type TypeCheckerConstructor<T, P...> = Template.TypeCheckerConstructor<T, P...>
    type FunctionalArg<T> = Template.FunctionalArg<T>
    type TypeChecker<ExtensionClass, Primitive> = Template.TypeChecker<ExtensionClass, Primitive>

local Util = require(script.Parent.Parent.Util)
    local CreateStandardInitial = Util.CreateStandardInitial
    local ExpectType = Util.ExpectType
    local Expect = Util.Expect

type CoroutineStatus = ("dead" | "suspended" | "running" | "normal")
type ThreadTypeChecker = TypeChecker<ThreadTypeChecker, thread> & {
    HasStatus: ((self: ThreadTypeChecker, Status: FunctionalArg<CoroutineStatus>) -> (ThreadTypeChecker));
};

local ThreadChecker: (() -> (ThreadTypeChecker)), ThreadCheckerClass = Template.Create("Thread")
ThreadCheckerClass._CacheConstruction = true
ThreadCheckerClass._Initial = CreateStandardInitial("thread")
ThreadCheckerClass._TypeOf = {"thread"}

local function _HasStatus(_, Thread, _, Status)
    local CurrentStatus = coroutine.status(Thread)

    if (CurrentStatus == Status) then
        return true
    end

    return false, `Expected thread to have status {Status}, got {CurrentStatus}`
end

--- Checks the coroutine's status against a given status string.
function ThreadCheckerClass:HasStatus(Status)
    ExpectType(Status, Expect.STRING_OR_FUNCTION, 1)

    return self:_AddConstraint(true, "HasStatus", _HasStatus, Status)
end

ThreadCheckerClass.InitialConstraint = ThreadCheckerClass.Status

return ThreadChecker