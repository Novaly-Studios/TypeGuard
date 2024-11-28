--!native
--!optimize 2
--!nonstrict

local IsArray = require(script.Parent.Parent.Shared.IsArray)

local function FreezeDeep(Structure)
    for Key, Value in Structure do
        if (type(Value) == "table") then
            FreezeDeep(Value)
        end
    end
    return table.freeze(Structure)
end

return table.freeze({
    Freeze = function(Call)
        return function(Existing, Template)
            return FreezeDeep(Call(Existing, Template))
        end
    end;
    Assert = function(Call)
        return function(Existing, Template)
            assert(type(Existing) == "table" and not IsArray(Existing), "Arg #1 was not a map")
            assert(type(Template) == "table" and not IsArray(Template), "Arg #2 was not a map")
            return Call(Existing, Template)
        end
    end;
})