local Result = {}

for _, Module in game.Selection:Get()[1]:GetChildren() do
    local Name = Module.Name

    if (Name == "init" or Name:match("%.spec") or Name:match("%_")) then
        continue
    end

    table.insert(Result, `{Name} = require(script:WaitForChild("{Name}"));`)
end

table.sort(Result)
print(table.concat(Result, "\n"))