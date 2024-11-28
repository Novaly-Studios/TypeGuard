--!native
--!optimize 2
--!nonstrict

local PREVENT_WRITE_MT = {
    __newindex = function(_, Key)
        error(`Attempt to write to non-existent key: {Key}`, 2)
    end;
}

--- Prevents writing of **new** keys to a table - slightly different to table.freeze.
--- Useful for preventing accidental reallocations or adding fields which aren't supposed
--- to be there once initialized.
local function SetUnresizable(Subject: any)
    setmetatable(Subject, PREVENT_WRITE_MT)
end

return SetUnresizable