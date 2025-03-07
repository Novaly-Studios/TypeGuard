--!native
--!optimize 2

if (not script) then
    script = game:GetService("ReplicatedFirst").TypeGuard.Roblox.CatalogSearchParams
end

local Template = require(script.Parent.Parent._Template)
    type TypeCheckerConstructor<T, P...> = Template.TypeCheckerConstructor<T, P...>
    type FunctionalArg<T> = Template.FunctionalArg<T>
    type TypeChecker<ExtensionClass, Primitive> = Template.TypeChecker<ExtensionClass, Primitive>
    type SelfReturn<T, P...> = Template.SelfReturn<T, P...>

type CatalogSearchParamsTypeChecker = TypeChecker<CatalogSearchParamsTypeChecker, CatalogSearchParams> & {

};

local Core = script.Parent.Parent.Core
    local Number = require(Core.Number)
        local Float = Number()
        local Int32 = Number():Integer(32)
    local Boolean = require(Core.Boolean)
        local DefaultBoolean = Boolean()
    local Object = require(Core.Object)
    local String = require(Core.String)
        local DefaultString = String()
    local Array = require(Core.Array)

local RbxEnum = require(script.Parent.Enum)
    local EnumCatalogSortType = RbxEnum(Enum.CatalogSortType)
    local EnumCatalogSortAggregation = RbxEnum(Enum.CatalogSortAggregation)
    local EnumCatalogCategoryFilter = RbxEnum(Enum.CatalogCategoryFilter)
    local EnumSalesTypeFilter = RbxEnum(Enum.SalesTypeFilter)
    local EnumBundleType = RbxEnum(Enum.BundleType)
    local EnumAvatarAssetType = RbxEnum(Enum.AvatarAssetType)
    local EnumCreatorTypeFilter = RbxEnum(Enum.CreatorTypeFilter)

local Checker = Object({
    SearchKeyword = DefaultString;
    MinPrice = Int32;
    MaxPrice = Int32;
    SortType = EnumCatalogSortType;
    SortAggregation = EnumCatalogSortAggregation;
    CategoryFilter = EnumCatalogCategoryFilter;
    SalesTypeFilter = EnumSalesTypeFilter;
    BundleTypes = Array(EnumBundleType);
    AssetTypes = Array(EnumAvatarAssetType);
    IncludeOffSale = DefaultBoolean;
    CreatorName = DefaultString;
    CreatorType = EnumCreatorTypeFilter;
    CreatorId = Float;
    Limit = Int32;
}):Unmap(function(Value)
    local Result = CatalogSearchParams.new()
    Result.SearchKeyword = Value.SearchKeyword
    Result.MinPrice = Value.MinPrice
    Result.MaxPrice = Value.MaxPrice
    Result.SortType = Value.SortType
    Result.SortAggregation = Value.SortAggregation
    Result.CategoryFilter = Value.CategoryFilter
    Result.SalesTypeFilter = Value.SalesTypeFilter
    Result.BundleTypes = Value.BundleTypes
    Result.AssetTypes = Value.AssetTypes
    Result.IncludeOffSale = Value.IncludeOffSale
    Result.CreatorName = Value.CreatorName
    Result.CreatorType = Value.CreatorType
    Result.CreatorId = Value.CreatorId
    Result.Limit = Value.Limit
    return Result
end):Strict():NoConstraints()
Checker.Type = "CatalogSearchParams"
Checker._TypeOf = {Checker.Type}

return function()
    return Checker
end :: TypeCheckerConstructor<CatalogSearchParamsTypeChecker>