local PREVENT_WRITE_MT = {
    __newindex = function(_, Key)
        error(`Attempt to write to non-existent key: {Key}`, 2)
    end;
}

--- Prevents writing of new keys to a table, thus (hopefully) preventing any reallocations.
local function SetUnresizable(Subject: any)
    setmetatable(Subject, PREVENT_WRITE_MT)
end

return SetUnresizable