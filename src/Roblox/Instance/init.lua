--!native
--!optimize 2

if (not script) then
    script = game:GetService("ReplicatedFirst").TypeGuard.TypeCheckers.Instance
end

local CollectionService = game:GetService("CollectionService")

local RunService = game:GetService("RunService")
    local IsClient = RunService:IsClient()

local Template = require(script.Parent.Parent._Template)
    type SignatureTypeCheckerInternal = Template.SignatureTypeCheckerInternal
    type TypeCheckerConstructor<T, P...> = Template.TypeCheckerConstructor<T, P...>
    type SignatureTypeChecker = Template.SignatureTypeChecker
    type FunctionalArg<T> = Template.FunctionalArg<T>
    type TypeChecker<ExtensionClass, Primitive> = Template.TypeChecker<ExtensionClass, Primitive>

local Util = require(script.Parent.Parent.Util)
    local CreateStandardInitial = Util.CreateStandardInitial
    local StructureStringMT = Util.StructureStringMT
    local AssertIsTypeBase = Util.AssertIsTypeBase
    local ExpectType = Util.ExpectType
    local Expect = Util.Expect

type InstanceTypeChecker = TypeChecker<InstanceTypeChecker, Instance> & {
    CheckAttributes: ((self: InstanceTypeChecker, FunctionalArg<{[string]: SignatureTypeChecker}>) -> (InstanceTypeChecker));
    SerializeScheme: ((self: InstanceTypeChecker, Type: "NetSync" | "Reference" | "Full") -> (InstanceTypeChecker));
    IsDescendantOf: ((self: InstanceTypeChecker, FunctionalArg<Instance>) -> (InstanceTypeChecker));
    CheckAttribute: ((self: InstanceTypeChecker, FunctionalArg<string>, FunctionalArg<SignatureTypeChecker>) -> (InstanceTypeChecker));
    HasAttributes: ((self: InstanceTypeChecker, FunctionalArg<{string}>) -> (InstanceTypeChecker));
    IsAncestorOf: ((self: InstanceTypeChecker, FunctionalArg<Instance>) -> (InstanceTypeChecker));
    HasAttribute: ((self: InstanceTypeChecker, FunctionalArg<string>) -> (InstanceTypeChecker));
    OfChildType: ((self: InstanceTypeChecker, FunctionalArg<SignatureTypeChecker>) -> (InstanceTypeChecker));
    OfStructure: ((self: InstanceTypeChecker, FunctionalArg<{[string]: SignatureTypeChecker}>) -> (InstanceTypeChecker));
    HasChild: ((self: InstanceTypeChecker, FunctionalArg<string>) -> (InstanceTypeChecker));
    HasTags: ((self: InstanceTypeChecker, FunctionalArg<{string}>) -> (InstanceTypeChecker));
    HasTag: ((self: InstanceTypeChecker, FunctionalArg<string>) -> (InstanceTypeChecker));
    Strict: ((self: InstanceTypeChecker) -> (InstanceTypeChecker));
    IsA: ((self: InstanceTypeChecker, FunctionalArg<string>) -> (InstanceTypeChecker));
};

local function Get(Inst, Key)
    return Inst[Key]
end

local function TryGet(Inst, Key)
    local Success, Result = pcall(Get, Inst, Key)

    if (Success) then
        return Result
    end

    return nil
end

-- For serialization: cache Instances with unique IDs so refs can be replicated. Only works when server recognizes the Instance first.
local INSTANCE_REF = "\36"

local UniqueIDToInstance = {}
local InstanceID = 0

CollectionService:GetInstanceAddedSignal(INSTANCE_REF):Connect(function(Target)
    local UniqueID = Target:GetAttribute(INSTANCE_REF)

    if (not UniqueID) then
        local Cancel = task.delay(30, task.cancel, coroutine.running())
        Target:GetAttributeChangedSignal(INSTANCE_REF):Wait()
        task.cancel(Cancel)
    end

    UniqueIDToInstance[UniqueID] = Target
end)

local function PackIntegerSigned(Int)
    return string.pack("I" .. (Int > 0 and math.log(Int, 256) or 0) // 1 + 1, Int)
end

local function UnpackIntegerSigned(Packed)
    return string.unpack("I" .. #Packed, Packed)
end

local function GetInstanceID(Target)
    local ID = Target:GetAttribute(INSTANCE_REF)
    
    if (ID) then
        return UnpackIntegerSigned(ID)
    elseif (IsClient) then
        error(`Instance refs must be serialized on the server before being sent to the client ({Target:GetFullName()})`)
    end

    local Temp = InstanceID + 1
    Target:SetAttribute(INSTANCE_REF, PackIntegerSigned(Temp))
    InstanceID = Temp
    return Temp
end

local function GetInstanceFromID(ID)
    local Result = UniqueIDToInstance[ID]

    if (not Result) then
        error(`Instance with ID {ID} not found - make sure it is serialized and replicated on the server`)
    end

    return Result
end

local InstanceChecker: TypeCheckerConstructor<InstanceTypeChecker, string? | ((any?) -> string)?, {[string]: SignatureTypeChecker}?>, InstanceCheckerClass = Template.Create("Instance")
InstanceCheckerClass._Initial = CreateStandardInitial("Instance")
InstanceCheckerClass._TypeOf = {"Instance"}

local function _OfStructure(SelfRef, InstanceRoot, SubTypes)
    -- Check all properties and children which should be in the Instance exist and the type check for each passes.
    for Key, Checker in SubTypes do
        local Value = TryGet(InstanceRoot, Key)
        local Success, SubMessage = Checker:_Check(Value)

        if (not Success) then
            return false, `{(typeof(Value) == "Instance" and "[Instance '" or "[Property '")}{Key}'] {SubMessage}`
        end
    end

    -- Check there are no extra children which shouldn't be in the Instance.
    if (SelfRef._Strict) then
        for _, Value in InstanceRoot:GetChildren() do
            local Key = Value.Name
            local Checker = SubTypes[Key]

            if (not Checker) then
                return false, `[Instance '{Key}'] unexpected (strict)`
            end
        end
    end

    return true
end

--- Ensures that an Instance has specific children and / or properties.
function InstanceCheckerClass:OfStructure(OriginalSubTypes)
    ExpectType(OriginalSubTypes, Expect.TABLE, 1)

    -- Just in case the user does any weird mutation.
    local SubTypesCopy = {}

    for Key, Value in OriginalSubTypes do
        AssertIsTypeBase(Value, Key)
        SubTypesCopy[Key] = Value
    end

    setmetatable(SubTypesCopy, StructureStringMT)

    return self:_AddConstraint(true, "OfStructure", _OfStructure, SubTypesCopy)
end

local function _IsA(_, InstanceRoot, InstanceIsA)
    if (not InstanceRoot:IsA(InstanceIsA)) then
        return false, `Expected {InstanceIsA}, got {InstanceRoot.ClassName}`
    end

    return true
end

--- Uses Instance.IsA to assert the type of an Instance.
function InstanceCheckerClass:IsA(InstanceIsA)
    ExpectType(InstanceIsA, Expect.STRING_OR_FUNCTION, 1)

    return self:_AddConstraint(true, "IsA", _IsA, InstanceIsA)
end

local function _OfChildType(_, InstanceRoot, Checker)
    for _, Child in InstanceRoot:GetChildren() do
        local Success, Result = Checker:_Check(Child)

        if (not Success) then
            return false, `Child {Child.Name} did not satisfy the given TypeChecker - {Result}`
        end
    end

    return true
end

--- Checks that all children of an Instance satisfy the given TypeChecker.
function InstanceCheckerClass:OfChildType(Checker)
    AssertIsTypeBase(Checker, 1)

    return self:_AddConstraint(true, "OfChildType", _OfChildType, Checker)
end

--- Serializes an Instance reference instead of 
function InstanceCheckerClass:SerializeScheme(Type)
    return self:Modify({
        _SerializeScheme = Type;
    })
end

--- Activates strict tag for OfStructure.
function InstanceCheckerClass:Strict()
    return self:Modify({
        _Strict = true;
    })
end

local function _HasTag(_, InstanceRoot, Tag)
    if (CollectionService:HasTag(InstanceRoot, Tag)) then
        return true
    end

    return false, `Expected tag '{Tag}' on Instance {InstanceRoot:GetFullName()}`
end

--- Checks if an Instance has a particular tag.
function InstanceCheckerClass:HasTag(Tag: string)
    ExpectType(Tag, Expect.STRING_OR_FUNCTION, 1)

    return self:_AddConstraint(false, "HasTag", _HasTag, Tag)
end

local function _HasAttribute(_, InstanceRoot, Attribute)
    if (InstanceRoot:GetAttribute(Attribute) ~= nil) then
        return true
    end

    return false, `Expected attribute '{Attribute}' to exist on Instance {InstanceRoot:GetFullName()}`
end

--- Checks if an Instance has a particular attribute.
function InstanceCheckerClass:HasAttribute(Attribute: string)
    ExpectType(Attribute, Expect.STRING_OR_FUNCTION, 1)

    return self:_AddConstraint(false, "HasAttribute", _HasAttribute, Attribute)
end

local function _CheckAttribute(_, InstanceRoot, Attribute, Checker)
    local Success, SubMessage = (Checker :: any):_Check(InstanceRoot:GetAttribute(Attribute))

    if (not Success) then
        return false, `Attribute '{Attribute}' not satisfied on Instance {InstanceRoot:GetFullName()}: {SubMessage}`
    end

    return true
end

--- Applies a TypeChecker to an Instance's expected attribute.
function InstanceCheckerClass:CheckAttribute(Attribute: string, Checker: SignatureTypeChecker)
    ExpectType(Attribute, Expect.STRING_OR_FUNCTION, 1)
    AssertIsTypeBase(Checker, 2)

    return self:_AddConstraint(false, "CheckAttribute", _CheckAttribute, Attribute, Checker)
end

local function _HasTags(_, InstanceRoot, Tags)
    for _, Tag in Tags do
        if (not CollectionService:HasTag(InstanceRoot, Tag)) then
            return false, `Expected tag '{Tag}' on Instance {InstanceRoot:GetFullName()}`
        end
    end

    return true
end

--- Checks if an Instance has a set of tags.
function InstanceCheckerClass:HasTags(Tags: {string})
    ExpectType(Tags, Expect.TABLE_OR_FUNCTION, 1)

    if (type(Tags) == "table") then
        for Index, Tag in Tags do
            assert(type(Tag) == "string", `Expected tag #{Index} to be a string`)
        end
    end

    return self:_AddConstraint(false, "HasTags", _HasTags, Tags)
end

local function _HasAttributes(_, InstanceRoot, Attributes)
    for _, Attribute in Attributes do
        if (InstanceRoot:GetAttribute(Attribute) == nil) then
            return false, `Expected attribute '{Attribute}' to exist on Instance {InstanceRoot:GetFullName()}`
        end
    end

    return true
end

--- Checks if an Instance has a set of attributes.
function InstanceCheckerClass:HasAttributes(Attributes: {string})
    ExpectType(Attributes, Expect.TABLE_OR_FUNCTION, 1)

    if (type(Attributes) == "table") then
        for Index, Attribute in Attributes do
            assert(type(Attribute) == "string", `Expected attribute #{Index} to be a string`)
        end
    end

    return self:_AddConstraint(false, "HasAttributes", _HasAttributes, Attributes)
end

local function _CheckAttributes(_, InstanceRoot, AttributeCheckers)
    for Attribute, Checker in AttributeCheckers do
        local Success, SubMessage = Checker:_Check(InstanceRoot:GetAttribute(Attribute))

        if (not Success) then
            return false, `Attribute '{Attribute}' not satisfied on Instance {InstanceRoot:GetFullName()}: {SubMessage}`
        end
    end

    return true
end

--- Applies a TypeChecker to an Instance's expected attribute.
function InstanceCheckerClass:CheckAttributes(AttributeCheckers: {SignatureTypeChecker})
    ExpectType(AttributeCheckers, Expect.TABLE, 1)

    for Attribute, Checker in AttributeCheckers do
        assert(type(Attribute) == "string", `Attribute '{Attribute}' was not a string`)
        AssertIsTypeBase(Checker, "")
    end

    return self:_AddConstraint(false, "CheckAttributes", _CheckAttributes, AttributeCheckers)
end

local function _IsDescendantOf(_, SubjectInstance, Instance)
    if (SubjectInstance:IsDescendantOf(Instance)) then
        return true
    end

    return false, `Expected Instance {SubjectInstance:GetFullName()} to be a descendant of {Instance:GetFullName()}`
end

--- Checks if an Instance is a descendant of a particular Instance.
function InstanceCheckerClass:IsDescendantOf(Instance)
    ExpectType(Instance, Expect.INSTANCE_OR_FUNCTION, 1)

    return self:_AddConstraint(true, "IsDescendantOf", _IsDescendantOf, Instance)
end

local function _IsAncestorOf(_, SubjectInstance, Instance)
    if (SubjectInstance:IsAncestorOf(Instance)) then
        return true
    end

    return false, `Expected Instance {SubjectInstance:GetFullName()} to be an ancestor of {Instance:GetFullName()}`
end

--- Checks if an Instance is an ancestor of a particular Instance.
function InstanceCheckerClass:IsAncestorOf(Instance)
    ExpectType(Instance, Expect.INSTANCE_OR_FUNCTION, 1)

    return self:_AddConstraint(false, "IsAncestorOf", _IsAncestorOf, Instance)
end

local function _HasChild(_, InstanceRoot, Name)
    if (InstanceRoot:FindFirstChild(Name)) then
        return true
    end

    return false, `Expected child '{Name}' to exist on Instance {InstanceRoot:GetFullName()}`
end

--- Checks if a particular child exists in an Instance.
function InstanceCheckerClass:HasChild(Name)
    ExpectType(Name, Expect.STRING_OR_FUNCTION, 1)

    return self:_AddConstraint(false, "HasChild", _HasChild, Name)
end

function InstanceCheckerClass:_UpdateSerialize()
    local SerializeScheme = self._SerializeScheme or "Full"

    if (SerializeScheme == "NetSync") then
        return {
            _Serialize = function(Buffer, Value, _Cache)
                Buffer.WriteUInt(32, GetInstanceID(Value))
            end;
            _Deserialize = function(Buffer, _Cache)
                return GetInstanceFromID(Buffer.ReadUInt(32))
            end;
        }
    end

    if (SerializeScheme == "Reference") then
        return {
            _Serialize = function(_Buffer, _Value, _Cache)
                error("Reference Instance serialization unimplemented")
            end;
            _Deserialize = function(_Buffer, _Cache)
                error("Reference Instance deserialization unimplemented")
            end;
        }
    end

    return {
        _Serialize = function(_Buffer, _Value, _Cache)
            error("Full Instance serialization unimplemented")
        end;
        _Deserialize = function(_Buffer, _Cache)
            error("Full Instance deserialization unimplemented")
        end;
    }
end

InstanceCheckerClass.InitialConstraints = {InstanceCheckerClass.IsA, InstanceCheckerClass.OfStructure}

return InstanceChecker