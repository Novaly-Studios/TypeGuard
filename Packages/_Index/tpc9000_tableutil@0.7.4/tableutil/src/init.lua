--!native
--!optimize 2
--!nonstrict

if (not script) then
    script = game:GetService("ReplicatedFirst").TableUtil
end

local FeaturesCache = {}

local Library = {
    Array = require(script.Array);
    Map = require(script.Map);
    Set = require(script.Set);
}

local Shared = script.Shared

local ValidFeatures = {
    Assert = true;
    Freeze = true;
}

--- Allows turning on and off extension functions which wrap over the core functions.
--- This allows the consumer to determine the compromise between security and performance.
--- Passing nothing will return the library with all features disabled.
function Library.WithFeatures(...: "Assert" | "Freeze"): typeof(Library)
    local Cache = {}
    for Index = 1, select("#", ...) do
        local Feature = select(Index, ...)
        assert(type(Feature) == "string", `Arg #{Index} invalid: must be a string`)
        assert(ValidFeatures[Feature], `Arg #{Index} invalid: must be one of ({table.concat(ValidFeatures, ", ")})`)
        table.insert(Cache, Feature)
    end
    table.sort(Cache) -- Ensures different orders of same set of strings go in the same cache key. Cache of X, Y = cache of Y, X and so on.

    local CacheKey = table.concat(Cache)
    local Cached = FeaturesCache[CacheKey]
    if (Cached) then
        return Cached
    end

    local Copy = table.clone(Library)
    for SubcategoryID, Subcategory in Library do
        if (type(Subcategory) == "table") then
            local SubcategoryCopy = table.clone(Subcategory)
            for FunctionID, Function in pairs(Subcategory) do -- Keep pairs here because of __call.
                local ModuleName = `{FunctionID}-Features`
                local FeatureModule = script[SubcategoryID]:FindFirstChild(ModuleName) or Shared:FindFirstChild(ModuleName)
                if (not FeatureModule) then
                    continue
                end
                for FeatureID, Feature in require(FeatureModule) do
                    if (not Cache[FeatureID]) then
                        continue
                    end
                    Function = Feature(Function)
                end
                SubcategoryCopy[FunctionID] = Function
            end
            Copy[SubcategoryID] = table.freeze(SubcategoryCopy)
        end
    end
    FeaturesCache[CacheKey] = Copy
    return table.freeze(Copy)
end

-- By default, all features are enabled. They can be disasbled for performance via "TableUtil.WithFeatures()" (pass no args).
local Default = Library.WithFeatures("Assert", "Freeze")
return Default