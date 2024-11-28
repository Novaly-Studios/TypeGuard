return table.freeze({
    BinarySearch = require(script.BinarySearch);
    Cut = require(script.Cut);
    Equals = require(script.Equals);
    Filter = require(script.Filter);
    FoldLeft = require(script.FoldLeft);
    FoldRight = require(script.FoldRight);
    GroupBy = require(script.GroupBy);
    Insert = require(script.Insert);
    IsOrdered = require(script.IsOrdered);
    Map = require(script.Map);
    Mean = require(script.Mean);
    Merge = require(script.Merge);
    MergeMany = require(script.MergeMany);
    MutableBinaryInsert = require(script.MutableBinaryInsert);
    MutableMerge = require(script.MutableMerge);
    MutableMergeMany = require(script.MutableMergeMany);
    MutableReverse = require(script.MutableReverse);
    MutableShuffle = require(script.MutableShuffle);
    Percentile = require(script.Percentile);
    Product = require(script.Product);
    Range = require(script.Range);
    Remove = require(script:FindFirstChild("Remove"));
    RemoveRange = require(script.RemoveRange);
    Reverse = require(script.Reverse);
    SelectFirst = require(script.SelectFirst);
    SelectLast = require(script.SelectLast);
    SelectRandom = require(script.SelectRandom);
    SelectWeighted = require(script.SelectWeighted);
    Shuffle = require(script.Shuffle);
    Sort = require(script.Sort);
    Sum = require(script.Sum);

    -- Shared
    IsArray = require(script.Parent.Shared.IsArray);
    IsMap = require(script.Parent.Shared.IsMap);
    IsMixed = require(script.Parent.Shared.IsMixed);
    IsPureArray = require(script.Parent.Shared.IsPureArray);
    IsPureMap = require(script.Parent.Shared.IsPureMap);
    Keys = require(script.Parent.Shared.Keys);
    Lockdown = require(script.Parent.Shared.Lockdown);
    SetUnresizable = require(script.Parent.Shared.SetUnresizable);
    SwapKeysValues = require(script.Parent.Shared.SwapKeysValues);
    Values = require(script.Parent.Shared.Values);
});