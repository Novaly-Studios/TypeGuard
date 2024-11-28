local SetType = require(script._SetType)
export type Set<T> = SetType.Set<T>

local Result = {
    FromValues = require(script.FromValues);
    Difference = require(script.Difference);
    Equals = require(script.Equals);
    FromKeys = require(script.FromKeys);
    Insert = require(script.Insert);
    Intersection = require(script.Intersection);
    IsProperSubset = require(script.IsProperSubset);
    IsSubset = require(script.IsSubset);
    Remove = require(script:FindFirstChild("Remove"));
    SymmetricDifference = require(script.SymmetricDifference);
    ToArray = require(script.ToArray);
    Union = require(script.Union);
};

return table.freeze(Result)