--!native
--!optimize 2

if (not script) then
    script = game:GetService("ReplicatedFirst").TypeGuard.Core.Optional
end

local Template = require(script.Parent.Parent._Template)
    type SignatureTypeChecker = Template.SignatureTypeChecker

local DefaultNil = require(script.Parent.Nil)()
local Or = require(script.Parent.Or)

return function(Type: SignatureTypeChecker)
    return Or(Type, DefaultNil)
end
