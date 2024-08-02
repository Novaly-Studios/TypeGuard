--- Locks down a table, freezing it and further preventing any reads.
local function Lockdown(Subject: any)
    for Key in Subject do
        Subject[Key] = nil
    end

    setmetatable(Subject, {
        __index = function(_, Key)
            error(`Attempted to read key from a locked down table: {Key}`, 2)
        end;
    })

    table.freeze(Subject)
end

return Lockdown