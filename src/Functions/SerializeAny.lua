--!native
--!optimize 2

local ReplicatedFirst = game:GetService("ReplicatedFirst")
    local TypeGuard = require(ReplicatedFirst.TypeGuard)

local Last = 0
local DivideTime = 1/240

local Any = TypeGuard.Any(1, function(Checker)
    return Checker:DefineDivide(function()
        local Duration = os.clock() - Last
        if (Duration > DivideTime) then
            task.wait()
            task.desynchronize()
            Last = os.clock()
        end
    end)
end)

local function SerializeAny(Value: any): buffer
    return Any:Serialize(Value, nil, true)
end

return SerializeAny