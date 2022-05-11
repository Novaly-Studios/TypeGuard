# Types

A constraint-based runtime assertion & type-checking library. Aims to replace all assertions and manual type checks with a convenient callable pattern.

## Usage Examples

```lua
local ReplicatedFirst = game:GetService("ReplicatedFirst")
local Types = reuqire(ReplicatedFirst:WaitForChild("Types"))

-- PARAMS
    -- 1: Check if all params are either integers between 10 and 20, or strings with at least 5 characters
    local Checker = Types.VariadicParams(
        Types.Number():Integer():Min(10):Max(20)
            :Or(Types.String():MinLength(5))
    )

    Checker(15, "ddddd") -- Pass
    Checker(15, "ddddd", "abc") -- Fail

    -- 2: Check if the first three parameters are numbers
    local Checker = Types.Params(
        Types.Number(),
        Types.Number(),
        Types.Number()
    )

    Checker(1, 2, 3) -- Pass
    Checker(1, 2, 3, 4) -- Pass
    Checker(1, "2", 3) -- Fail

-- INSTANCES, STRUCTURES & PRIMITIVE TYPES

    -- 1: Check a two-layer array and ensure the first item is either a number or a string
    local Checker = Types.Array():OfStructure({
        [1] = Types.Array():OfStructure({
            [1] = Types.Number():Or(Types.String()):Alias("NumberOrString");
        });
    })

    Checker:Assert({{"test"}}) -- Pass
    Checker:Assert({{false}}) -- Fail

    -- 2: Check a structure recursively and its types, ensuring they are all integer numbers
    local Int = Types.Number():Integer()
    local Checker = Types.Object({
        X = Int;
        Y = Int;
        Z = Int;

        W = Types.Object({
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
    local Test = Types.Instance("Workspace"):OfStructure({
        Camera = Types.Instance("Camera");
        Baseplate = Types.Instance("BasePart"):OfStructure({
            Texture = Types.Instance("Texture");
        });
        SpawnLocation = Types.Instance("BasePart");
    })

    Test:Assert(game:GetService("Workspace")) -- Pass (if on default baseplate)
    Test:Strict():Assert(game:GetService("Workspace")) -- Fail (even if on default baseplate, as Terrain, Camera, and SpawnLocation would also exist)

    -- 4: Checking against Enum values and Enum classes (with disjunction)
    local Checker = Types.Enum(Enum.Material):Or( Types.Enum(Enum.AccessoryType.Hat) )
    Checker:Assert(Enum.Material.Air) -- Pass
    Checker:Assert(Enum.AccessoryType.Hat) -- Pass
```