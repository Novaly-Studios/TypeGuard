return table.freeze({
    Changes = require(script.Changes);
    Count = require(script.Count);
    CreatePatchDeep = require(script.CreatePatchDeep);
    Creations = require(script.Creations);
    Equals = require(script.Equals);
    Filter = require(script.Filter);
    Flatten = require(script.Flatten);
    FromKeyValueArray = require(script.FromKeyValueArray);
    GroupBy = require(script.GroupBy);
    Map = require(script.Map);
    Merge = require(script.Merge);
    MergeDeep = require(script.MergeDeep);
    MergeMany = require(script.MergeMany);
    MutableMerge = require(script.MutableMerge);
    MutableMergeDeep = require(script.MutableMergeDeep);
    MutableMergeMany = require(script.MutableMergeMany);
    Removals = require(script.Removals);
    ToKeyValueArray = require(script.ToKeyValueArray);

    -- Shared
    CloneDeep = require(script.Parent.Shared.CloneDeep);
    IsArray = require(script.Parent.Shared.IsArray);
    IsMap = require(script.Parent.Shared.IsMap);
    IsMixed = require(script.Parent.Shared.IsMixed);
    IsPureArray = require(script.Parent.Shared.IsPureArray);
    IsPureMap = require(script.Parent.Shared.IsPureMap);
    Keys = require(script.Parent.Shared.Keys);
    Lockdown = require(script.Parent.Shared.Lockdown);
    -- MixedMergeDeep = require(script.Parent.Shared.MixedMergeDeep);
    SetUnresizable = require(script.Parent.Shared.SetUnresizable);
    SwapKeysValues = require(script.Parent.Shared.SwapKeysValues);
    Values = require(script.Parent.Shared.Values);
});