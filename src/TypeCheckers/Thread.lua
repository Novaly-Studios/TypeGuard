local Template = require(script.Parent:WaitForChild("_Template"))
    type TypeCheckerConstructor<T, P...> = Template.TypeCheckerConstructor<T, P...>
    type TypeChecker<ExtensionClass, Primitive> = Template.TypeChecker<ExtensionClass, Primitive>
    type SelfReturn<T, P...> = Template.SelfReturn<T, P...>

local Util = require(script.Parent.Parent:WaitForChild("Util"))
    local CreateStandardInitial = Util.CreateStandardInitial
    local ExpectType = Util.ExpectType
    local Expect = Util.Expect

type ThreadTypeChecker = TypeChecker<ThreadTypeChecker, thread> & {
    IsDead: SelfReturn<ThreadTypeChecker>;
    IsSuspended: SelfReturn<ThreadTypeChecker>;
    IsRunning: SelfReturn<ThreadTypeChecker>;
    IsNormal: SelfReturn<ThreadTypeChecker>;
    HasStatus: SelfReturn<ThreadTypeChecker, string | (any?) -> string>;
};

local ThreadChecker: TypeCheckerConstructor<ThreadTypeChecker>, ThreadCheckerClass = Template.Create("Thread")
ThreadCheckerClass._Initial = CreateStandardInitial("thread")

--- Checks if the coroutine is dead.
function ThreadCheckerClass:IsDead()
    return self:HasStatus("dead")
end

--- Checks if the coroutine is suspended / yielded.
function ThreadCheckerClass:IsSuspended()
    return self:HasStatus("suspended")
end

--- Checks if the coroutine is running.
function ThreadCheckerClass:IsRunning()
    return self:HasStatus("running")
end

--- Checks if the coroutine is waiting for another coroutine to finish.
function ThreadCheckerClass:IsNormal()
    return self:HasStatus("normal")
end

--- Checks the coroutine's status against a given status string.
function ThreadCheckerClass:HasStatus(Status)
    ExpectType(Status, Expect.STRING_OR_FUNCTION, 1)

    return self:_AddConstraint(true, "HasStatus", function(_, Thread, Status)
        local CurrentStatus = coroutine.status(Thread)

        if (CurrentStatus == Status) then
            return true
        end

        return false, `Expected thread to have status '{Status}', got {CurrentStatus}`
    end, Status)
end

ThreadCheckerClass.InitialConstraint = ThreadCheckerClass.HasStatus

return ThreadChecker