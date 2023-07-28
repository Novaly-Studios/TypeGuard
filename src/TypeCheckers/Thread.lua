local Template = require(script.Parent:WaitForChild("_Template"))
    type TypeCheckerConstructor<T, P...> = Template.TypeCheckerConstructor<T, P...>
    type TypeChecker<ExtensionClass, Primitive> = Template.TypeChecker<ExtensionClass, Primitive>
    type SelfReturn<T, P...> = Template.SelfReturn<T, P...>

local Util = require(script.Parent.Parent:WaitForChild("Util"))
    local CreateStandardInitial = Util.CreateStandardInitial
    local ExpectType = Util.ExpectType
    local Expect = Util.Expect

type CoroutineStatus = "dead" | "suspended" | "running" | "normal"
type ThreadTypeChecker = TypeChecker<ThreadTypeChecker, thread> & {
    HasStatus: SelfReturn<ThreadTypeChecker, CoroutineStatus | ((any?) -> CoroutineStatus)>;
};

local ThreadChecker: TypeCheckerConstructor<ThreadTypeChecker>, ThreadCheckerClass = Template.Create("Thread")
ThreadCheckerClass._Initial = CreateStandardInitial("thread")

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

ThreadCheckerClass.InitialConstraint = ThreadCheckerClass.Status

return ThreadChecker