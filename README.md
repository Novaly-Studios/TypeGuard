# TypeGuard

A runtime assertion & type-checking library. This aims to replace most assertions and manual type checks with a consistent, callable pattern.

## Usage Examples

```lua
local ReplicatedFirst = game:GetService("ReplicatedFirst")
local TypeGuard = require(ReplicatedFirst:WaitForChild("TypeGuard"))

-- Example #1: standard params, simple
local AssertRandomParams = TypeGuard.Params(
    TypeGuard.String(),
    TypeGuard.Boolean(),
    TypeGuard.Any()
)

local function Test(P: string, Q: boolean, R: any)
    AssertRandomParams(P, Q, R)
    -- ...
end

-- Example #2: variadic params + "reject non-integer" constraint
local AssertSumInts = TypeGuard.VariadicParams(TypeGuard.Number():Integer())

local function SumInts(...: number)
    AssertSumInts(...)
    -- ...
end

-- Example #3: validating tables passed to RemoteEvents recursively
local AssertValidTest = TypeGuard.Params(
    TypeGuard.Instance("Player"):IsDescendantOf(game:GetService("Players")),
    TypeGuard.Object({
        P = TypeGuard.Number();
        Q = TypeGuard.Number():Integer():IsAValueIn({1, 2, 3, 4, 5});
        R = TypeGuard.Array(TypeGuard.String()):MaxLength(100);
    }):Strict()
)

SomeRemoteEvent.OnServerEvent:Connect(function(Player: Player, TestData: {P: number, Q: number, R: {string}})
    AssertValidTest(Player, TestData)
    -- ...
end)

-- Example #4: TypeChecker disjunction
local AssertStringOrNumberOrBoolean = TypeGuard.Params(
    TypeGuard.String():Or(TypeGuard.Number()):Or(TypeGuard.Boolean()):FailMessage("expected a string, number, or boolean")
)

local function Test(Input: string | number | boolean)
    AssertStringOrNumberOrBoolean(Input)
    -- ...
end

-- Example #5: TypeChecker conjunction
local AssertStructureCombined = TypeGuard.Params(
    -- 'And' only really makes sense on non-strict structural checks for arrays, objects, and Instances
    TypeGuard.Object({
        X = TypeGuard.Number();
    }):And(
        TypeGuard.Object({
            Y = TypeGuard.Number();
        })
    ):And(
        TypeGuard.Object({
            Z = TypeGuard.Number();
        })
    )
)

local function Test(Input: {X: number} & {Y: number} & {Z: number})
    AssertStructureCombined(Input)
    -- ...
end

-- Example #6: context passing (is a character's health > some random number?)
local AssertTestContext = TypeGuard.ParamsWithContext(
    TypeGuard.Instance("Model", {
        Humanoid = TypeGuard.Instance("Humanoid", {
            Health = TypeGuard.Number():GreaterThan(function(Context)
                return Context.Compare
            end)
        })
    })
)

local function Test(Root: Model)
    AssertTestContext({Compare = math.random(1, 50)}, Root)
    -- ...
end

-- Example #7: Optional params
local AssertTestOptional = TypeGuard.Params(
    TypeGuard.String(),
    TypeGuard.Vector3():Optional()
)

local function Test(X: string, Y: Vector3)
    AssertTestOptional(X, Y)
    -- ...
end

-- Example #8: Instance filtering via wrapping check into predicate
local IsHumanoidAlive = TypeGuard.Instance("Model", {
    Humanoid = TypeGuard.Instance("Humanoid", { -- Scans children recursively
        Health = TypeGuard.Number():GreaterThan(0); -- Scans properties
    });
}):WrapCheck()

local AliveHumanoids = SomeTableLibrary.Filter(Workspace:GetChildren(), IsHumanoidAlive)
```

## Best Practices
Avoid re-construction of TypeCheckers. They are copied with each added constraint or change, and are supposed to exist outside of frequently called functions. If you need to pass dynamic data down, use context & functional constraints.

## Major Initiatives
- Split up each TypeChecker into separate modules
- Find a way to make the type metadata compatible with Roblox LSP (intellisense is critical to the intuitiveness of this library)
- Constraint disjunction (e.g. `TypeGuard.String():IsAValueIn({"X", "Y"}):Or():IsAValueIn({"Z", "W"})`)