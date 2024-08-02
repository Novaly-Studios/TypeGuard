local SetType = require(script:WaitForChild("_SetType"))
export type Set<T> = SetType.Set<T>

local Result = {
    Difference = require(script:WaitForChild("Difference"));
    Equals = require(script:WaitForChild("Equals"));
    FromKeys = require(script:WaitForChild("FromKeys"));
    FromValues = require(script:WaitForChild("FromValues"));
    Insert = require(script:WaitForChild("Insert"));
    Intersection = require(script:WaitForChild("Intersection"));
    IsProperSubset = require(script:WaitForChild("IsProperSubset"));
    IsSubset = require(script:WaitForChild("IsSubset"));
    Remove = require(script:WaitForChild("Remove"));
    SymmetricDifference = require(script:WaitForChild("SymmetricDifference"));
    ToArray = require(script:WaitForChild("ToArray"));
    Union = require(script:WaitForChild("Union"));
};

setmetatable(Result, { -- Allows for Set({"X", "Y", "Z"})
    __call = function(_, ...)
        return Result.FromValues(...)
    end;
})

return Result