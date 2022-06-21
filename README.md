# TypeGuard

A constraint-based runtime assertion & type-checking library. Aims to replace all assertions and manual type checks with a convenient callable pattern.

## Usage Examples

```lua
local ReplicatedFirst = game:GetService("ReplicatedFirst")
local TypeGuard = require(ReplicatedFirst:WaitForChild("TypeGuard"))

-- PARAMS
    -- 1: Check if all params are either integers between or equal to 10 and 20, or strings with at least 5 characters
    local Checker = TypeGuard.VariadicParams(
        TypeGuard.Number():Integer():RangeInclusive(10, 20)
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
    Checker(1, 2, 3, 4) -- Fail
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
    local Test = TypeGuard.Instance("Workspace", {
        Camera = TypeGuard.Instance("Camera");
        Baseplate = TypeGuard.Instance("BasePart", {
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

    -- 5: Passing functions to constraints (they evaluate when checking)
    local Checker = TypeGuard.String():IsAKeyIn(function()
        local WorkspaceChildren = {}

        for _, Item in pairs(Workspace:GetChildren()) do
            WorkspaceChildren[Item.Name] = true
        end

        return WorkspaceChildren
    end)

    Checker:Check("Terrain") -- Pass
    Checker:Check("NonExistentInstance") -- Fail

    -- 6: Constraint "not" or "inverse" operation (flips the last constraint in the sequence)
    local Checker = TypeGuard.String()
                        :IsAValueIn({"1", "2"}):Negate()
                        :Contains("3"):Negate()
                        :Pattern("%d+")
    
    print(Checker:Check("100")) -- Pass
    print(Checker:Check("2")) -- Fail
    print(Checker:Check("3")) -- Fail
    print(Checker:Check("AHHHH")) -- Fail
    print(Checker:Check("498545")) -- Pass

    -- 7: Single context support (works well with functional params on constraints + passing values inside a function)
    -- We want the param to contain the string of the current hour
    local CheckParams = TypeGuard.ParamsWithContext( TypeGuard.String():Contains(function(CurrentTime)
        return CurrentTime
    end) )

    local function GetCurrentHour()
        return os.date():match("%d+:(%d+):%d+")
    end

    local function Stuff(Input)
        CheckParams(GetCurrentHour(), Input)
    end

-- EXTRA FUN
    local Predicate = TypeGuard.Instance("Model"):OfStructure({
        Humanoid = TypeGuard.Instance("Humanoid"):OfStructure({ -- Can scan children recursively
            Health = TypeGuard.Number():GreaterThan(0); -- Also can scan properties
        });
    }):WrapCheck()

    local AliveHumanoids = TableUtil.Array.Filter1D(Workspace:GetChildren(), Predicate)
```