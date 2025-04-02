# TypeGuard

A runtime assertion, type-checking, and serialization library. This aims to replace most assertions and manual type checks with a consistent, callable pattern.

## Usage Examples

### 1: standard params, simple

```lua
local AssertRandomParams = TypeGuard.Params(
    TypeGuard.String(),
    TypeGuard.Boolean(),
    TypeGuard.Any()
)

local function Test(P: string, Q: boolean, R: any)
    AssertRandomParams(P, Q, R)
    -- ...
end
```

### 2: each provided arg must be an integer

```lua
local AssertSumInts = TypeGuard.Variadic(TypeGuard.Number():Integer())
local function SumInts(...: number)
    AssertSumInts(...)
    -- ...
end
```

### 3: TypeChecker disjunction with a custom failure message

```lua
local AssertStringOrNumberOrBoolean = TypeGuard.Params(
    TypeGuard.Or(
        TypeGuard.String()
        TypeGuard.Number()
        TypeGuard.Boolean()
    ):FailMessage("expected a string, number, or boolean")
)

local function Test(Input: string | number | boolean)
    AssertStringOrNumberOrBoolean(Input)
    -- ...
end
```

### 4: TypeChecker conjunction

```lua
local AssertStructureCombined = TypeGuard.Params(
    TypeGuard.Object({
        X = TypeGuard.Number();
    }):And(TypeGuard.Object({
        Y = TypeGuard.Number();
    })):And(TypeGuard.Object({
        Z = TypeGuard.Number();
    }))
)

local function Test(Input: {X: number} & {Y: number} & {Z: number})
    AssertStructureCombined(Input)
    -- ...
end
```

### 5: context passing (functional constraint): assert that the provided Model a descendant of Workspace

```lua
local AssertTestContext = TypeGuard.ParamsWithContext(
    TypeGuard.Instance("Model"):IsDescendantOf(function(Context)
        return Context.Reference
    end)
)

local function Test(Root: Model)
    AssertTestContext({Reference = workspace}, Root)
    -- ...
end
```

### 6: Optional params

```lua
local AssertTestOptional = TypeGuard.Params(
    TypeGuard.String(),
    TypeGuard.Optional(TypeGuard.Vector3())
)

local function Test(X: string, Y: Vector3?)
    AssertTestOptional(X, Y)
    -- ...
end
```

### 7: validating tables passed to RemoteEvents recursively, with various principles combined

```lua
local AssertValidTest = TypeGuard.Params(
    TypeGuard.Instance("Player"):IsDescendantOf(game:GetService("Players")),

    TypeGuard.Object({
        P = TypeGuard.Number():IsAValueIn({1, 2, 3, 4, 5});
        Q = TypeGuard.Number(-100, 100):Integer();
        R = TypeGuard.Array(TypeGuard.String()):MaxLength(100);

        S = TypeGuard.Object({
            Key1 = TypeGuard.Optional(TypeGuard.String());
            Key2 = TypeGuard.Enum(Enum.Material);
        }):Strict();

        T = TypeGuard.Number():IsInfinite():Negate():IsClose(123, 0.5):Negate(); -- "number should not be infinite and should not be close to 123"
    }):Strict()
)

SomeRemoteEvent.OnServerEvent:Connect(function(Player: Player, TestData: {P: number, Q: number, R: {string}, S: {Key1: string?, Key2: Enum.Material?}, T: number})
    AssertValidTest(Player, TestData)
    -- ...
end)
```

### 8: Instance filtering via wrapping check into predicate: find all alive Humanoids whose characters are not tagged with "Ignore"

```lua
local IsHumanoidAlive = TypeGuard.Instance("Model", {
    Humanoid = TypeGuard.Instance("Humanoid", { -- Scans children recursively
        Health = TypeGuard.Number():GreaterThan(0); -- Scans properties
    });
}):HasTag("Ignore"):Negate():WrapCheck()

local AliveHumanoids = SomeTableLibrary.Filter(Workspace:GetChildren(), IsHumanoidAlive)
```

### 9: constructing a checker from a template object

```lua
local Instances = Instance.new("Model")
    local Part1 = Instance.new("Part")
    Part1.Name = "Part1"
    Part1.Parent = Instances
    local Part2 = Instance.new("Part")
    Part2.Name = "Part2"
    Part2.Parent = Instances

local Checker = TypeGuard.FromTemplate({
    X = 1;
    Y = 2;
    Z = 3;

    P = {
        Q = Vector3.new();
        R = Instances;
    };

    Arr = {1, 2, "X", "Y"}; -- Accepts strings or numbers
})
-- ^ created a deep Object TypeChecker
```

### 10: serialization & deserialization

```lua
local Any = TypeGuard.BaseAny()
local Serialize1 = Any:Serialize({
    X = 1;
    Y = 2;
    P = {"AHHHH", "----", { 
        Q = true;
        R = false;
    }};
})
print(Any:Deserialize(Serialize1))

local TestObject = TypeGuard.Object({
    X = TypeGuard.Number(0, 100);
    Y = TypeGuard.Number(0, 10):Integer();
    Z = TypeGuard.String():MaxLength(1000);

    W = TypeGuard.Optional(TypeGuard.Object():OfKeyType(TypeGuard.Boolean()):OfValueType(TypeGuard.String()));
})
local Serialize2 = TestObject:Serialize({
    X = 1;
    Y = 2;
    Z = "------------";
    W = {
        [true] = "H";
        [false] = "H";
    };
})
print(TestObject:Deserialize(Serialize2))
```

## Best Practices

Avoid construction or copying of TypeCheckers for performance reasons. TypeCheckers are copied with each added constraint or change, and are supposed to exist outside of frequently called functions. If you need to pass dynamic data down, use context & functional constraints.
