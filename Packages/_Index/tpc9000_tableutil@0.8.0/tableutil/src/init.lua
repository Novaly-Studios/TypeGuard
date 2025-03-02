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

local ValidFeatures = {"Assert", "Freeze"}
local DefaultFeatures = {"Assert", "Freeze"}

type Feature = ("Assert" | "Freeze")

--- Allows turning on and off extension functions which wrap over the core functions.
--- This allows the consumer to determine the compromise between security and performance.
--- Passing nothing will return the library with all features disabled.
function Library.WithFeatures(...: Feature): typeof(Library)
    local Cache = {}
    local FeatureCount = select("#", ...)

    for Index = 1, FeatureCount do
        local Feature = select(Index, ...)
        assert(type(Feature) == "string", `Arg #{Index} invalid: must be a string`)
        assert(table.find(ValidFeatures, Feature), `Arg #{Index} invalid: must be one of ({table.concat(ValidFeatures, ", ")})`)
        table.insert(Cache, Feature)
    end

    table.sort(Cache) -- Ensures different orders of same set of strings go in the same cache key. Cache of X, Y = cache of Y, X and so on.

    -- local AllFeatures = (FeatureCount == #DefaultFeatures)
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

                local Features = require(FeatureModule)

                local function GetFunction()
                    return Function
                end

                for FeatureID, Feature in Features do
                    if (FeatureID == "Init") then
                        continue
                    end

                    if (not table.find(Cache, FeatureID)) then
                        continue
                    end

                    Function = Feature(Function, GetFunction)
                end

                -- Some functions might need a self-reference as the final arg, but only during its initialization.
                -- This prevents each recursion call from calling this Init function again. Better performance.
                local FinalFunction = Function

                if (Features.Init) then
                    FinalFunction = Features.Init(Function, GetFunction)
                end

                SubcategoryCopy[FunctionID] = FinalFunction
            end

            Copy[SubcategoryID] = table.freeze(SubcategoryCopy)
        end
    end

    FeaturesCache[CacheKey] = Copy
    return table.freeze(Copy)
end

--- Turning on additional / experimental features on top of the default recommended features.
function Library.WithAdditionalFeatures(...: Feature): typeof(Library)
    local NewFeatures = table.clone(DefaultFeatures)

    for Index = 1, select("#", ...) do
        table.insert(NewFeatures, (select(Index, ...)))
    end

    return Library.WithFeatures(unpack(NewFeatures))
end

-- By default, all features are enabled. They can be disasbled for performance via "TableUtil.WithFeatures()" (pass no args).
local Default = Library.WithFeatures(unpack(DefaultFeatures))
return Default