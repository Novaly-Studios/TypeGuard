--!native
--!optimize 2

if (not script and Instance) then
    script = game:GetService("ReplicatedFirst").TypeGuard.Core.Array
end

local Template = require(script.Parent.Parent._Template)
    type SignatureTypeChecker = Template.SignatureTypeChecker

local Indexable = require(script.Parent.Indexable)

return function(Type)
    return Indexable():PureArray(Type)
end