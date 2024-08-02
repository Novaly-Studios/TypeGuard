local MutableReverse = require(script.Parent:WaitForChild("MutableReverse"))

--- Flips all items in an array.
local function Reverse<T>(Array: {T}): {T}
    local Copy = table.clone(Array)
    MutableReverse(Copy)
    return Copy
end

return Reverse