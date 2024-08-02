local MutableMergeMany = require(script.Parent:WaitForChild("MutableMergeMany"))

--- Merges various tables together.
local function MergeMany(...)
    return MutableMergeMany({}, ...)
end

return MergeMany