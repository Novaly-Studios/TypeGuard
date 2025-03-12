local CollectionService = game:GetService("CollectionService")

local function anyfn(...) return ({} :: any) end
it = it or anyfn
expect = expect or anyfn
describe = describe or anyfn

return function()
    local TypeGuard = require(script.Parent.Parent.Parent)
    local Base = TypeGuard.Instance()

    describe("Init", function()
        it("should reject non-Instances", function()
            expect(Base:Check("Test")).to.equal(false)
            expect(Base:Check(1)).to.equal(false)
            expect(Base:Check(function() end)).to.equal(false)
            expect(Base:Check(nil)).to.equal(false)
            expect(Base:Check({})).to.equal(false)
        end)

        it("should accept Instances", function()
            expect(Base:Check(Instance.new("Model"))).to.equal(true)
        end)

        it("should use the IsA constraint as the initial constraint", function()
            local Test = TypeGuard.Instance("Model")

            expect(Test:Check(Instance.new("Model"))).to.equal(true)
            expect(Test:Check(Instance.new("Part"))).to.equal(false)
        end)

        it("should use the IsA constraint + the OfStructure constraint if two values are passed", function()
            local Test = TypeGuard.Instance("Model", {
                Name = TypeGuard.String():Equals("TestName");
            })

            expect(Test:Check(Instance.new("Model"))).to.equal(false)

            local Sample = Instance.new("Model")
            Sample.Name = "TestName"

            expect(Test:Check(Sample)).to.equal(true)
        end)
    end)

    describe("IsA", function()
        it("should reject non-Instances", function()
            expect(Base:IsA("Folder"):Check("Folder")).to.equal(false)
            expect(Base:IsA("Folder"):Check(1)).to.equal(false)
            expect(Base:IsA("Folder"):Check(function() end)).to.equal(false)
            expect(Base:IsA("Folder"):Check(nil)).to.equal(false)
            expect(Base:IsA("Folder"):Check({})).to.equal(false)
        end)

        it("should accept Instances of the specified type string (or function returning type string)", function()
            expect(Base:IsA("Folder"):Check(Instance.new("Folder"))).to.equal(true)
            expect(Base:IsA(function()
                return "Folder"
            end):Check(Instance.new("Folder"))).to.equal(true)
        end)

        it("should reject Instances of other classes", function()
            expect(Base:IsA("Folder"):Check(Instance.new("Part"))).to.equal(false)
            expect(Base:IsA(function()
                return "Folder"
            end):Check(Instance.new("Part"))).to.equal(false)
        end)
    end)

    describe("OfStructure", function()
        it("should reject non-Instances", function()
            expect(function()
                Base:OfStructure({Test = "Test"})
            end).to.throw()

            expect(function()
                Base:OfStructure({Test = 1})
            end).to.throw()

            expect(function()
                Base:OfStructure({Test = function() end})
            end).to.throw()
        end)

        it("should accept a map of children and/or properties", function()
            expect(function()
                Base:OfStructure({
                    Test = TypeGuard.Instance("Folder");
                    Name = TypeGuard.String();
                })
            end).to.never.throw()
        end)

        it("should reject Instances that do not match the structure", function()
            expect(
                Base:OfStructure({
                    Test = TypeGuard.Instance("Folder");
                    Name = TypeGuard.String();
                }):Check(Instance.new("Folder"))
            ).to.equal(false)
        end)

        it("should accept Instances that match the structure", function()
            local SampleTree = Instance.new("Folder")
                local Test = Instance.new("Folder")
                Test.Name = "Test"
                Test.Parent = SampleTree

            expect(
                Base:OfStructure({
                    Test = TypeGuard.Instance("Folder");
                    Name = TypeGuard.String();
                }):Check(SampleTree)
            ).to.equal(true)
        end)

        it("should reject Instances that do not match the structure recursively", function()
            local SampleTree = Instance.new("Folder")
                local Test = Instance.new("Folder")
                Test.Name = "Test"
                Test.Parent = SampleTree
                    local Test2 = Instance.new("Part")
                    Test2.Name = "Test2"
                    Test2.Parent = Test

            expect(
                Base:OfStructure({
                    Test = TypeGuard.Instance("Folder"):OfStructure({
                        Test2 = TypeGuard.Instance():OfStructure({
                            Name = TypeGuard.String():Equals("Incorrect Name");
                        });
                        Name = TypeGuard.String():Equals("Test");
                    });
                    Name = TypeGuard.String():Equals("Folder");
                }):Check(Test)
            ).to.equal(false)
        end)

        it("should accept Instances that match the structure recursively", function()
            local SampleTree = Instance.new("Folder")
                local Test = Instance.new("Folder")
                Test.Name = "Test"
                Test.Parent = SampleTree
                    local Test2 = Instance.new("Part")
                    Test2.Name = "Test2"
                    Test2.Parent = Test

            expect(
                Base:OfStructure({
                    Test = TypeGuard.Instance("Folder"):OfStructure({
                        Test2 = TypeGuard.Instance():OfStructure({
                            Name = TypeGuard.String():Equals("Test2");
                        });
                        Name = TypeGuard.String():Equals("Test");
                    });
                    Name = TypeGuard.String():Equals("Folder");
                }):Check(Test)
            ).to.equal(false)
        end)
    end)

    describe("Strict + OfStructure", function()
        it("should reject extra flat children", function()
            local SampleTree = Instance.new("Folder")
                local Test = Instance.new("Folder")
                Test.Name = "Test"
                Test.Parent = SampleTree
                local Test2 = Instance.new("Folder")
                Test2.Name = "Test2"
                Test2.Parent = SampleTree

            expect(
                Base:OfStructure({
                    Test = TypeGuard.Instance("Folder");
                }):Strict():Check(SampleTree)
            ).to.equal(false)

            expect(
                Base:OfStructure({
                    Test = TypeGuard.Instance("Folder");
                    Test2 = TypeGuard.Instance("Folder");
                }):Strict():Check(SampleTree)
            ).to.equal(true)
        end)

        it("should reject extra children recursively", function()
            local SampleTree = Instance.new("Folder")
                local Test = Instance.new("Folder")
                Test.Name = "Test"
                Test.Parent = SampleTree
                    local Test2 = Instance.new("Folder")
                    Test2.Name = "Test2"
                    Test2.Parent = Test
                    local Test22 = Instance.new("Folder")
                    Test22.Name = "Test22"
                    Test22.Parent = Test

            expect(
                Base:OfStructure({
                    Test = TypeGuard.Instance("Folder"):OfStructure({
                        Test2 = TypeGuard.Instance("Folder");
                        -- No Test22, should reject
                    }):Strict();
                }):Strict():Check(SampleTree)
            ).to.equal(false)

            expect(
                Base:OfStructure({
                    Test = TypeGuard.Instance("Folder"):OfStructure({
                        Test2 = TypeGuard.Instance("Folder");
                        Test22 = TypeGuard.Instance("Folder");
                    }):Strict();
                }):Strict():Check(SampleTree)
            ).to.equal(true)
        end)
    end)

    describe("HasTag", function()
        it("should reject non-Instances", function()
            expect(Base:HasTag("Test"):Check("Test")).to.equal(false)
            expect(Base:HasTag("Test"):Check(1)).to.equal(false)
            expect(Base:HasTag("Test"):Check(function() end)).to.equal(false)
            expect(Base:HasTag("Test"):Check(nil)).to.equal(false)
            expect(Base:HasTag("Test"):Check({})).to.equal(false)
        end)

        it("should accept Instances with the specified tag", function()
            local Test = Instance.new("Folder")
            CollectionService:AddTag(Test, "TestTag")
            expect(TypeGuard.Instance():HasTag("TestTag"):Check(Test)).to.equal(true)
            expect(TypeGuard.Instance():HasTag(function()
                return "TestTag"
            end):Check(Test)).to.equal(true)
        end)

        it("should reject Instances without the specified tag", function()
            local Test = Instance.new("Folder")
            expect(TypeGuard.Instance():HasTag("TestTag"):Check(Test)).to.equal(false)
            expect(TypeGuard.Instance():HasTag(function()
                return "TestTag"
            end):Check(Test)).to.equal(false)
        end)
    end)

    describe("IsAncestorOf", function()
        it("should reject non-Instances", function()
            expect(Base:IsAncestorOf(Instance.new("Folder")):Check("Test")).to.equal(false)
            expect(Base:IsAncestorOf(Instance.new("Folder")):Check(1)).to.equal(false)
            expect(Base:IsAncestorOf(Instance.new("Folder")):Check(function() end)).to.equal(false)
            expect(Base:IsAncestorOf(Instance.new("Folder")):Check(nil)).to.equal(false)
            expect(Base:IsAncestorOf(Instance.new("Folder")):Check({})).to.equal(false)
        end)

        it("should accept Instances that are ancestors of the specified Instance", function()
            local Test = Instance.new("Folder")
            local Test2 = Instance.new("Folder")
            Test2.Parent = Test
            local Test3 = Instance.new("Folder")
            Test3.Parent = Test2

            expect(TypeGuard.Instance():IsAncestorOf(Test2):Check(Test)).to.equal(true)
            expect(TypeGuard.Instance():IsAncestorOf(Test3):Check(Test)).to.equal(true)

            expect(TypeGuard.Instance():IsAncestorOf(function()
                return Test2
            end):Check(Test)).to.equal(true)
            expect(TypeGuard.Instance():IsAncestorOf(function()
                return Test3
            end):Check(Test)).to.equal(true)
        end)
    end)

    describe("IsDescendantOf", function()
        it("should reject non-Instances", function()
            expect(Base:IsDescendantOf(Instance.new("Folder")):Check("Test")).to.equal(false)
            expect(Base:IsDescendantOf(Instance.new("Folder")):Check(1)).to.equal(false)
            expect(Base:IsDescendantOf(Instance.new("Folder")):Check(function() end)).to.equal(false)
            expect(Base:IsDescendantOf(Instance.new("Folder")):Check(nil)).to.equal(false)
            expect(Base:IsDescendantOf(Instance.new("Folder")):Check({})).to.equal(false)
        end)

        it("should accept Instances that are descendants of the specified Instance", function()
            local Test = Instance.new("Folder")
            local Test2 = Instance.new("Folder")
            Test2.Parent = Test
            local Test3 = Instance.new("Folder")
            Test3.Parent = Test2

            expect(TypeGuard.Instance():IsDescendantOf(Test):Check(Test2)).to.equal(true)
            expect(TypeGuard.Instance():IsDescendantOf(Test):Check(Test3)).to.equal(true)

            expect(TypeGuard.Instance():IsDescendantOf(function()
                return Test
            end):Check(Test2)).to.equal(true)
            expect(TypeGuard.Instance():IsDescendantOf(function()
                return Test
            end):Check(Test3)).to.equal(true)
        end)
    end)

    describe("HasAttribute", function()
        it("should reject non-strings and non-functions as 1st param", function()
            expect(function()
                Base:HasAttribute(1)
            end).to.throw()

            expect(function()
                Base:HasAttribute(true)
            end).to.throw()

            expect(function()
                Base:HasAttribute(nil)
            end).to.throw()
        end)

        it("should accept a string a 1st param", function()
            expect(function()
                Base:HasAttribute("Test")
            end).never.to.throw()
        end)

        it("should reject non-Instances on check", function()
            expect(Base:HasAttribute("Test"):Check("Test")).to.equal(false)
            expect(Base:HasAttribute("Test"):Check(1)).to.equal(false)
            expect(Base:HasAttribute("Test"):Check(function() end)).to.equal(false)
            expect(Base:HasAttribute("Test"):Check(nil)).to.equal(false)
            expect(Base:HasAttribute("Test"):Check({})).to.equal(false)
        end)

        it("should accept Instances with the specified attribute", function()
            local Test = Instance.new("Folder")
            Test:SetAttribute("TestAttribute", true)
            expect(TypeGuard.Instance():HasAttribute("TestAttribute"):Check(Test)).to.equal(true)
            expect(TypeGuard.Instance():HasAttribute(function()
                return "TestAttribute"
            end):Check(Test)).to.equal(true)
        end)

        it("should reject Instances without the specified attribute", function()
            local Test = Instance.new("Folder")
            expect(TypeGuard.Instance():HasAttribute("TestAttribute"):Check(Test)).to.equal(false)
            expect(TypeGuard.Instance():HasAttribute(function()
                return "TestAttribute"
            end):Check(Test)).to.equal(false)
        end)
    end)

    describe("CheckAttribute", function()
        it("should reject non-strings and non-functions as 1st param", function()
            expect(function()
                Base:CheckAttribute(1)
            end).to.throw()

            expect(function()
                Base:CheckAttribute(true)
            end).to.throw()

            expect(function()
                Base:CheckAttribute(nil)
            end).to.throw()
        end)

        it("should reject non-TypeCheckers as 2nd param", function()
            expect(function()
                Base:CheckAttribute("Test", 1)
            end).to.throw()

            expect(function()
                Base:CheckAttribute("Test", true)
            end).to.throw()

            expect(function()
                Base:CheckAttribute("Test", function() end)
            end).to.throw()

            expect(function()
                Base:CheckAttribute("Test", nil)
            end).to.throw()
        end)

        it("should accept a string & TypeChecker as params", function()
            expect(function()
                Base:CheckAttribute("Test", TypeGuard.Number())
            end).never.to.throw()
        end)

        it("should reject non-Instances on check", function()
            expect(Base:CheckAttribute("Test", TypeGuard.String()):Check("Test")).to.equal(false)
            expect(Base:CheckAttribute("Test", TypeGuard.String()):Check(1)).to.equal(false)
            expect(Base:CheckAttribute("Test", TypeGuard.String()):Check(function() end)).to.equal(false)
            expect(Base:CheckAttribute("Test", TypeGuard.String()):Check(nil)).to.equal(false)
            expect(Base:CheckAttribute("Test", TypeGuard.String()):Check({})).to.equal(false)
        end)

        it("should accept Instances with the specified attribute", function()
            local Test = Instance.new("Folder")
            Test:SetAttribute("TestAttribute", 123)
            expect(TypeGuard.Instance():CheckAttribute("TestAttribute", TypeGuard.Number()):Check(Test)).to.equal(true)
            expect(TypeGuard.Instance():CheckAttribute(function()
                return "TestAttribute"
            end, TypeGuard.Number()):Check(Test)).to.equal(true)
        end)

        it("should reject Instances without the specified attribute", function()
            local Test = Instance.new("Folder")
            expect(TypeGuard.Instance():CheckAttribute("TestAttribute", TypeGuard.Number()):Check(Test)).to.equal(false)
            expect(TypeGuard.Instance():CheckAttribute(function()
                return "TestAttribute"
            end, TypeGuard.Number()):Check(Test)).to.equal(false)
        end)
    end)

    describe("HasTags", function()
        it("should reject non-string arrays as first arg", function()
            expect(function()
                Base:HasTags(1)
            end).to.throw()

            expect(function()
                Base:HasTags(true)
            end).to.throw()

            expect(function()
                Base:HasTags(nil)
            end).to.throw()
        end)

        it("should accept a string array as first arg", function()
            expect(function()
                Base:HasTags({"Test"})
            end).never.to.throw()

            expect(function()
                Base:HasTags({"Test", "Test2"})
            end).never.to.throw()
        end)

        it("should accept if all the tags are present", function()
            local Test = Instance.new("Folder")
            CollectionService:AddTag(Test, "Test")
            CollectionService:AddTag(Test, "Test2")
            expect(TypeGuard.Instance():HasTags({"Test", "Test2"}):Check(Test)).to.equal(true)
            expect(TypeGuard.Instance():HasTags(function()
                return {"Test", "Test2"}
            end):Check(Test)).to.equal(true)
        end)

        it("should reject if not all the tags are present", function()
            local Test = Instance.new("Folder")
            CollectionService:AddTag(Test, "Test")
            expect(TypeGuard.Instance():HasTags({"Test", "Test2"}):Check(Test)).to.equal(false)
            expect(TypeGuard.Instance():HasTags(function()
                return {"Test", "Test2"}
            end):Check(Test)).to.equal(false)
        end)

        it("should reject if none of the tags are present", function()
            local Test = Instance.new("Folder")
            expect(TypeGuard.Instance():HasTags({"Test", "Test2"}):Check(Test)).to.equal(false)
            expect(TypeGuard.Instance():HasTags(function()
                return {"Test", "Test2"}
            end):Check(Test)).to.equal(false)
        end)
    end)

    describe("HasAttributes", function()
        it("should reject non-string arrays as first arg", function()
            expect(function()
                Base:HasAttributes(1)
            end).to.throw()

            expect(function()
                Base:HasAttributes(true)
            end).to.throw()

            expect(function()
                Base:HasAttributes(nil)
            end).to.throw()
        end)

        it("should accept a string array as first arg", function()
            expect(function()
                Base:HasAttributes({"Test"})
            end).never.to.throw()

            expect(function()
                Base:HasAttributes({"Test", "Test2"})
            end).never.to.throw()
        end)

        it("should accept if all the attributes are present", function()
            local Test = Instance.new("Folder")
            Test:SetAttribute("Test", true)
            Test:SetAttribute("Test2", false)
            expect(TypeGuard.Instance():HasAttributes({"Test", "Test2"}):Check(Test)).to.equal(true)
            expect(TypeGuard.Instance():HasAttributes(function()
                return {"Test", "Test2"}
            end):Check(Test)).to.equal(true)
        end)

        it("should reject if not all the attributes are present", function()
            local Test = Instance.new("Folder")
            Test:SetAttribute("Test", 123)
            expect(TypeGuard.Instance():HasAttributes({"Test", "Test2"}):Check(Test)).to.equal(false)
            expect(TypeGuard.Instance():HasAttributes(function()
                return {"Test", "Test2"}
            end):Check(Test)).to.equal(false)
        end)

        it("should reject if none of the attributes are present", function()
            local Test = Instance.new("Folder")
            expect(TypeGuard.Instance():HasAttributes({"Test", "Test2"}):Check(Test)).to.equal(false)
            expect(TypeGuard.Instance():HasAttributes(function()
                return {"Test", "Test2"}
            end):Check(Test)).to.equal(false)
        end)
    end)

    describe("CheckAttributes", function()
        it("should reject non-tables as first arg", function()
            expect(function()
                Base:CheckAttributes(1)
            end).to.throw()

            expect(function()
                Base:CheckAttributes(true)
            end).to.throw()

            expect(function()
                Base:CheckAttributes(nil)
            end).to.throw()
        end)

        it("should reject tables with non-TypeCheckers as values or non-strings as keys", function()
            expect(function()
                Base:CheckAttributes({TypeGuard.String()})
            end).to.throw()

            expect(function()
                Base:CheckAttributes({Test = "P"})
            end).to.throw()
        end)

        it("should accept tables with TypeCheckers as values and strings as keys", function()
            expect(function()
                Base:CheckAttributes({Test = TypeGuard.String()})
            end).never.to.throw()

            expect(function()
                Base:CheckAttributes({
                    P = TypeGuard.String();
                    Q = TypeGuard.Number();
                })
            end).never.to.throw()
        end)

        it("should correctly check attribute types", function()
            local Test = Instance.new("Folder")
            Test:SetAttribute("Test", "Test")
            Test:SetAttribute("Test2", 123)

            expect(Base:CheckAttributes({
                Test = TypeGuard.String();
                Test2 = TypeGuard.Number();
            }):Check(Test)).to.equal(true)

            Test:SetAttribute("Test2", "TestString")

            expect(Base:CheckAttributes({
                Test = TypeGuard.String();
                Test2 = TypeGuard.Number();
            }):Check(Test)).to.equal(false)

            Test:SetAttribute("Test2", nil)

            expect(Base:CheckAttributes({
                Test = TypeGuard.String();
                Test2 = TypeGuard.Number();
            }):Check(Test)).to.equal(false)
        end)
    end)

    describe("OfChildType", function()
        it("should reject non-InstanceCheckers as first arg", function()
            expect(function()
                Base:OfChildType(1)
            end).to.throw()

            expect(function()
                Base:OfChildType(true)
            end).to.throw()

            expect(function()
                Base:OfChildType(nil)
            end).to.throw()
        end)

        it("should accept InstanceCheckers as first arg", function()
            expect(function()
                Base:OfChildType(TypeGuard.Instance())
            end).never.to.throw()
        end)

        it("should accept if all children are of the correct type", function()
            local Test = Instance.new("Folder")
            local Test2 = Instance.new("Folder")
            Test2.Parent = Test
            local Test3 = Instance.new("Folder")
            Test3.Parent = Test
            expect(TypeGuard.Instance():OfChildType(TypeGuard.Instance("Folder")):Check(Test)).to.equal(true)
        end)

        it("should reject if at least one child deviates from the correct type", function()
            local Test = Instance.new("Folder")
            local Test2 = Instance.new("Folder")
            Test2.Parent = Test
            local Test3 = Instance.new("Folder")
            Test3.Parent = Test
            local Test4 = Instance.new("Model")
            Test4.Parent = Test
            Test4.Name = "Test4"
            expect(TypeGuard.Instance():OfChildType(TypeGuard.Instance("Folder")):Check(Test)).to.equal(false)
        end)
    end)
end