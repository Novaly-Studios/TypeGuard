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

    return (table.isfrozen(Structure) and Structure or table.freeze(Structure))
end

return table.freeze({
    Freeze = function(Call)
        return function(Structure)
            return FreezeDeep(Call(Structure))
        end
    end;
    Assert = function(Call)
        return function(Structure)
            assert(type(Structure) == "table" and not IsArray(Structure), "Arg #1 was not a map")

            return Call(Structure)
        end
    end;
})