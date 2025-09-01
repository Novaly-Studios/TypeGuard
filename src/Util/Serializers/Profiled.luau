--!optimize 2
--!native

if (not script and Instance) then
    script = game:GetService("ReplicatedFirst").TypeGuard.Util.Encoders.BaseN
end

local Types = require(script.Parent._Types)

local tblclone = table.clone

local function ProfiledSerializer(Serializer: Types.Serializer)
    local Result: Types.Serializer = tblclone(Serializer)

    for Key, Value in Result do
        Result[Key] = function(...)
            debug.profilebegin(Key)
            local Result = Value(...)
            debug.profileend()
            return Result
        end
    end

    return Result
end

return ProfiledSerializer