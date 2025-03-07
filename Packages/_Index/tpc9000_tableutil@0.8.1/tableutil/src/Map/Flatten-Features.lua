--!native
--!optimize 2
--!nonstrict

local IsArray = require(script.Parent.Parent.Shared.IsArray)

return table.freeze({
    Freeze = function(Call)
        return function(Structure, DepthLimit)
            return table.freeze(Call(Structure, DepthLimit))
        end
    end;
    Assert = function(Call)
        return function(Structure, DepthLimit)
            assert(type(Structure) == "table" and not IsArray(Structure), "Arg #1 was not a map")
            assert(DepthLimit == nil or type(DepthLimit) == "number", "Arg #2 was not a number or nil")

            return Call(Structure, DepthLimit)
        end
    end;
})