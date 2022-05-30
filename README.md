# TypeGuard

A constraint-based runtime assertion & type-checking library. Aims to replace all assertions and manual type checks with a convenient callable pattern.

## Usage Examples

```lua
local ReplicatedFirst = game:GetService("ReplicatedFirst")
local TypeGuard = require(ReplicatedFirst:WaitForChild("TypeGuard"))

-- PARAMS
    -- 1: Check if all params are either integers between 10 and 20, or strings with at least 5 characters
    local Checker = TypeGuard.VariadicParams(
        TypeGuard.Number():Integer():Min(10):Max(20)
            :Or(TypeGuard.String():MinLength(5))
    )

    Checker(15, "ddddd") -- Pass
    Checker(15, "ddddd", "abc") -- Fail

    -- 2: Check if the first three parameters are numbers
    local Checker = TypeGuard.Params(
        TypeGuard.Number(),
        TypeGuard.Number(),
        TypeGuard.Number()
    )

    Checker(1, 2, 3) -- Pass
    Checker(1, 2, 3, 4) -- Pass
    Checker(1, "2", 3) -- Fail

-- INSTANCES, STRUCTURES & PRIMITIVE TYPES

    -- 1: Check a two-layer array and ensure the first item is either a number or a string
    local Checker = TypeGuard.Array():OfStructure({
        [1] = TypeGuard.Array():OfStructure({
            [1] = TypeGuard.Number():Or(TypeGuard.String()):Alias("NumberOrString");
        });
    })

    Checker:Assert({{"test"}}) -- Pass
    Checker:Assert({{false}}) -- Fail

    -- 2: Check a structure recursively and its types, ensuring they are all integer numbers
    local Int = TypeGuard.Number():Integer()
    local Checker = TypeGuard.Object({
        X = Int;
        Y = Int;
        Z = Int;

        W = TypeGuard.Object({
            Test = Int;
        }):Strict()
    })

    Checker:Assert({
        X = 1;
        Y = 1;
        Z = 1;

        W = {
            Test = 1;
        };
    }) -- Pass

    Checker:Assert({
        X = 1;
        Y = 1;
        Z = 1;

        W = {
            Test = 1;
            H = 1;
        };
    }) -- Fail (strict check, unexpected field in W: H)

    -- 3: Check the structure of Workspace on a blank baseplate game
    local Test = TypeGuard.Instance("Workspace"):OfStructure({
        Camera = TypeGuard.Instance("Camera");
        Baseplate = TypeGuard.Instance("BasePart"):OfStructure({
            Texture = TypeGuard.Instance("Texture");
        });
        SpawnLocation = TypeGuard.Instance("BasePart");
    })

    Test:Assert(game:GetService("Workspace")) -- Pass (if on default baseplate)
    Test:Strict():Assert(game:GetService("Workspace")) -- Fail (even if on default baseplate, as Terrain, Camera, and SpawnLocation would also exist)

    -- 4: Checking against Enum values and Enum classes (with disjunction)
    local Checker = TypeGuard.Enum(Enum.Material):Or( TypeGuard.Enum(Enum.AccessoryType.Hat) )
    Checker:Assert(Enum.Material.Air) -- Pass
    Checker:Assert(Enum.AccessoryType.Hat) -- Pass

-- EXTRA FUN
    local Predicate = TypeGuard.Instance("Model"):OfStructure({
        Humanoid = TypeGuard.Instance("Humanoid"):OfStructure({ -- Can scan children recursively
            Health = TypeGuard.Number():GreaterThan(0); -- Also can scan properties
        });
    }):WrapCheck()

    local AliveHumanoids = TableUtil.Array.Filter1D(Workspace:GetChildren(), Predicate)
```