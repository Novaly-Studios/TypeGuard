local function anyfn(...) return ({} :: any) end
it = it or anyfn
expect = expect or anyfn
describe = describe or anyfn

return function()
    local GetValues = require(script.Parent.Parent.Core._TestValues)
    local TypeGuard = require(script.Parent.Parent)
    local Base = TypeGuard.CatalogSearchParams()

    describe("Init", function()
        it("should reject non-CatalogSearchParams", function()
            for _, Value in GetValues("CatalogSearchParams") do
                expect(Base:Check(Value)).to.equal(false)
            end
        end)

        it("should accept CatalogSearchParams", function()
            expect(Base:Check(CatalogSearchParams.new())).to.equal(true)
        end)
    end)

    describe("Serialize, Deserialize", function()
        it("should correctly serialize & deserialize CatalogSearchParams", function()
            local Test = CatalogSearchParams.new()
            Test.SearchKeyword = "AHHHH"
            Test.MinPrice = 10
            Test.MaxPrice = 330
            Test.SortType = Enum.CatalogSortType.RecentlyCreated
            Test.SortAggregation = Enum.CatalogSortAggregation.Past3Days
            Test.CategoryFilter = Enum.CatalogCategoryFilter.Premium
            Test.SalesTypeFilter = Enum.SalesTypeFilter.Collectibles
            Test.BundleTypes = {Enum.BundleType.Animations, Enum.BundleType.DynamicHead}
            Test.AssetTypes = {Enum.AvatarAssetType.Face, Enum.AvatarAssetType.MoodAnimation}
            Test.IncludeOffSale = true
            Test.CreatorName = "Creator"
            Test.CreatorType = Enum.CreatorTypeFilter.Group
            Test.CreatorId = 17165546
            Test.Limit = 100
            expect(Base:Deserialize(Base:Serialize(Test))).to.equal(Test)
        end)
    end)
end