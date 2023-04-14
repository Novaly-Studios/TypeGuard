local TypeGuard = require(game:GetService("ReplicatedFirst"):WaitForChild("TypeGuard"))

local function GenerateTests(Context: string, TG)
    -- Thanks Copilot
    local ComplexObject = TG.Object({
        Age = TG.Number();
        Name = TG.String();
        Pets = TG.Object():OfKeyType(TG.String()):OfValueType(TG.String());
        Friends = TG.Array(TG.String());
        Instances = TG.Array(
            TG.Instance("Workspace"):OfStructure({
                Camera = TG.Instance("Camera");
                Terrain = TG.Instance("Terrain");
            })
        );
    }):Strict()

    local Complex = TG.Params(ComplexObject)
    local ComplexCached = ComplexObject:Cached()
    local ComplexCached1Arg = TG.Params(ComplexCached)
    local ComplexCached5Arg = TG.Params(ComplexCached, ComplexCached, ComplexCached, ComplexCached, ComplexCached)
    local ComplexCached10Arg = TG.Params(ComplexCached, ComplexCached, ComplexCached, ComplexCached, ComplexCached, ComplexCached, ComplexCached, ComplexCached, ComplexCached, ComplexCached)

    local Data = {
        Age = 10;
        Name = "Bob";
        Pets = {
            ["Dog"] = "Spot";
            ["Cat"] = "Fluffy";
        };
        Friends = {"Alice", "Charlie"};
        Instances = {workspace, workspace, workspace, workspace, workspace};
    }

    local Simple1Arg = TG.Params(TG.Number())
    local Simple5Arg = TG.Params(TG.Number(), TG.Number(), TG.Number(), TG.Number(), TG.Number())
    local Simple10Arg = TG.Params(TG.Number(), TG.Number(), TG.Number(), TG.Number(), TG.Number(), TG.Number(), TG.Number(), TG.Number(), TG.Number(), TG.Number())

    local SimpleCheck = TG.Number()

    return {
        [Context .. "SC"] = function()
            for Iter = 1, 10e3 do
                SimpleCheck:Check(Iter)
            end
        end;

        [Context .. "S1A"] = function()
            for Iter = 1, 10e3 do
                Simple1Arg(Iter)
            end
        end;

        [Context .. "S5A"] = function()
            for Iter = 1, 10e3 do
                Simple5Arg(Iter, Iter, Iter, Iter, Iter)
            end
        end;

        [Context .. "S10A"] = function()
            for Iter = 1, 10e3 do
                Simple10Arg(Iter, Iter, Iter, Iter, Iter, Iter, Iter, Iter, Iter, Iter)
            end
        end;

        [Context .. "C1A"] = function()
            for _ = 1, 100 do
                Complex(Data)
            end
        end;

        [Context .. "CC1A"] = function()
            for _ = 1, 100 do
                ComplexCached1Arg(Data)
            end
        end;

        [Context .. "CC5A"] = function()
            for _ = 1, 100 do
                ComplexCached5Arg(Data, Data, Data, Data, Data)
            end
        end;

        [Context .. "CC10A"] = function()
            for _ = 1, 100 do
                ComplexCached10Arg(Data, Data, Data, Data, Data, Data, Data, Data, Data, Data)
            end
        end;
    };
end

local CombinedTests = {}
local OldTG = game:GetService("ReplicatedFirst"):WaitForChild("TypeGuard"):FindFirstChild("Old")

if (OldTG) then
    for Name, Test in GenerateTests("Old", require(OldTG)) do
        CombinedTests[Name] = Test
    end
end

for Name, Test in GenerateTests(">New", TypeGuard) do
    CombinedTests[Name] = Test
end

return {
    ParameterGenerator = function()
        return
    end;

    Functions = CombinedTests;
};