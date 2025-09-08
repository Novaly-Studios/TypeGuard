--!native
--!optimize 2

if (not script and Instance) then
    script = game:GetService("ReplicatedFirst").TypeGuard.Roblox.Instance
end

local CollectionService = game:GetService("CollectionService")
local AssetService = game:GetService("AssetService")

--[[ local RunService = game:GetService("RunService")
    local IsClient = RunService:IsClient() ]]

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

local TableUtil = require(script.Parent.Parent.Parent.TableUtil).WithFeatures()
    local Merge = TableUtil.Map.Merge

local API = require(script.API) :: any

local Core = script.Parent.Parent.Core
    local Cacheable = require(Core.Cacheable)
    local Indexable = require(Core.Indexable)
    local Number = require(Core.Number)
    local String = require(Core.String)
    local Array = require(Core.Array)

--#region Roblox API Quirks Handling
local NoneContent = Content.none
local Creators = {
    MeshPart = function(Data)
        local MeshContent = Data.MeshContent
        if (MeshContent == NoneContent or MeshContent == nil) then
            return Instance.new("MeshPart")
        end

        local MeshPart = AssetService:CreateMeshPartAsync(MeshContent, {
            CollisionFidelity = Data.CollisionFidelity;
            RenderFidelity = Data.RenderFidelity;
            FluidFidelity = Data.FluidFidelity;
        })

        Data.CollisionFidelity = nil
        Data.RenderFidelity = nil
        Data.FluidFidelity = nil
        Data.MeshContent = nil

        return MeshPart
    end;
}

local PropertyModifiedOverwrite = {
    ["Any/Capabilities"] = false;

    ["MeshPart/MeshContent"] = true;
    ["MeshPart/MeshId"] = false;

    ["Attachment/WorldCFrame"] = false;
    ["Attachment/Position"] = false;
}

-- Sometimes Instance API serialization tags have no means to serialize certain properties
-- so we need to turn them on manually.
local ForceSerializeTags = {
    ["BasePart/Color"] = {
        CanLoad = true;
        CanSave = true;
    };
    ["BasePart/Size"] = {
        CanLoad = true;
        CanSave = true;
    };
}
--#endregion

--#region Roblox Instance API Functions
local ResetPropertyToDefault = game.ResetPropertyToDefault

local function _SetProperty(Target: Instance, Key: string, Value: any)
    Target[Key] = Value
end

local function SetProperty(Target: Instance, Key: string, Value: any): boolean
    local Success, Result = pcall(_SetProperty, Target, Key, Value)

    if (Success) then
        return true
    end
    
    task.defer(warn, `Failed to set property {Key} on {Target:GetFullName()}:\n{Result}`)
    return false
end

local function _GetProperty(Target: Instance, Key: string): any?
    return Target[Key]
end

local function GetProperty(Target: Instance, Key: string): (boolean, any?)
    local Success, Result = pcall(_GetProperty, Target, Key)

    if (Success) then
        return true, Result
    end

    task.defer(warn, `Failed to get property {Key} on {Target:GetFullName()}:\n{Result}`)
    return false, nil
end

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

-- Have to suffer with this until Roblox implements IsPropertyModified.
local function IsPropertyModified(Target: Instance, Key: string): boolean
    local OverwriteForClass = PropertyModifiedOverwrite[Target.ClassName .. "/" .. Key]
    if (OverwriteForClass ~= nil) then
        return OverwriteForClass
    end

    local OverwriteForAny = PropertyModifiedOverwrite["Any/" .. Key]
    if (OverwriteForAny ~= nil) then
        return OverwriteForAny
    end

    local Success, Temp = GetProperty(Target, Key)
    if (not Success) then
        return false
    end

    local CouldReset = pcall(ResetPropertyToDefault, Target, Key)
    if (CouldReset) then
        local Result = (Target[Key] ~= Temp)
        SetProperty(Target, Key, Temp)
        return Result
    end

    return false
end

local InstanceNew = Instance.new

local function DeferredPathWarn(FakeInstance, Message)
    local Path = ""
    local Parent = FakeInstance

    while (Parent) do
        Path = (Parent.Name or "<Instance>") .. "." .. Path
        Parent = Parent.Parent
    end

    warn(`Failed to create instance {Path:sub(1, #Path - 1)}:\n{Message}`)
end

local function CreateInstance(ClassName)
    if (ClassName == "EditableImage") then
        return AssetService:CreateEditableImage()
    end

    if (ClassName == "EditableMesh") then
        return AssetService:CreateEditableMesh()
    end

    local Success, Result = pcall(InstanceNew, ClassName)

    if (Success) then
        return Result
    end

    local Return = {}
    task.defer(DeferredPathWarn, Return, Result)
    return Return
end
--#endregion

--#region Instance Properties Setup
local CreatableInstanceNameToID = {}

local InstanceNameToID = {}
local InstanceIDToName = {}

local PropertyNameToID = {}
local PropertyIDToName = {}

local InstanceNameToPropertiesSerializerInherited = {} :: {
    [string]: {
        [string]: SignatureTypeChecker;
    }
}

local InstanceTypesInitialized = false

local PropertyID
    local PropertyIDDeserialize
    local PropertyIDSerialize

local InstanceID
    local InstanceIDDeserialize
    local InstanceIDSerialize

local function InitInstanceTypes()
    if (InstanceTypesInitialized) then
        return false
    end

    InstanceTypesInitialized = true

    local InstanceNameToPropertiesInherited = {} :: {
        [string]: {
            [string]: string;
        };
    }

    local InstanceNameToPropertiesWithSuperclass = {} :: {
        [string]: {
            Superclass: string?;
            Properties: {[string]: string};
        };
    }

    for _, Data in API.Classes do
        local InstanceName = Data.Name

        local Definition = {}
        local Properties = {}
        Definition.Superclass = Data.Superclass
        Definition.Properties = Properties

        for _, Member in Data.Members do
            if (Member.MemberType ~= "Property") then
                continue
            end

            local Tags = Member.Tags

            if (Tags and (table.find(Tags, "ReadOnly") or table.find(Tags, "Hidden") or table.find(Tags, "NotScriptable"))) then
                continue
            end

            local PropertyName = Member.Name
            local Serialization = ForceSerializeTags[`{InstanceName}/{PropertyName}`] or Member.Serialization

            if (not (Serialization.CanSave and Serialization.CanLoad)) then
                continue
            end

            if (PropertyName == "Parent") then
                continue
            end

            if (PropertyNameToID[PropertyName] == nil) then
                table.insert(PropertyIDToName, PropertyName)
                PropertyNameToID[PropertyName] = true
            end

            Properties[PropertyName] = Member.ValueType.Name
        end

        if (pcall(Instance.new, InstanceName)) then
            table.insert(CreatableInstanceNameToID, InstanceName)
        end

        table.insert(InstanceIDToName, InstanceName)
        InstanceNameToPropertiesWithSuperclass[InstanceName] = Definition
    end

    table.sort(PropertyIDToName)
    table.sort(InstanceIDToName)
    table.clear(InstanceNameToID)
    table.clear(PropertyNameToID)

    for InstanceID, InstanceName in InstanceIDToName do
        InstanceNameToID[InstanceName] = InstanceID
    end

    for PropertyID, PropertyName in PropertyIDToName do
        PropertyNameToID[PropertyName] = PropertyID
    end

    local Any = (require(script.Parent.Any) :: any)(nil, true)

    for InstanceName, Data in InstanceNameToPropertiesWithSuperclass do
        local Properties = {}

        while (Data) do
            for PropertyName, PropertyType in Data.Properties do
                Properties[PropertyName] = PropertyType
            end

            Data = InstanceNameToPropertiesWithSuperclass[Data.Superclass]
        end

        InstanceNameToPropertiesInherited[InstanceName] = Properties
    end

    for InstanceName, Properties in InstanceNameToPropertiesInherited do
        local Serializers = {}

        for Key, Value in Properties do
            Serializers[Key] = Any
        end

        InstanceNameToPropertiesSerializerInherited[InstanceName] = Serializers
    end

    -- table.clear(API)
    API = nil

    PropertyID = Number(1, #PropertyIDToName):Integer()
    PropertyIDDeserialize = PropertyID._Deserialize
    PropertyIDSerialize = PropertyID._Serialize

    InstanceID = Number(1, #InstanceIDToName):Integer()
    InstanceIDDeserialize = InstanceID._Deserialize
    InstanceIDSerialize = InstanceID._Serialize

    return true
end
--#endregion

type InstanceTypeChecker = TypeChecker<InstanceTypeChecker, Instance> & {
    CheckAttributes: ((self: InstanceTypeChecker, FunctionalArg<{[string]: SignatureTypeChecker}>) -> (InstanceTypeChecker));
    SerializeScheme: ((self: InstanceTypeChecker, Type: "Reference" | "Full") -> (InstanceTypeChecker));
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

--[[ -- For serialization: cache Instances with unique IDs so refs can be replicated. Only works when server recognizes the Instance first.
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
end ]]

local InstanceChecker: TypeCheckerConstructor<InstanceTypeChecker, string? | ((any?) -> string)?, {[string]: SignatureTypeChecker}?>, InstanceCheckerClass = Template.Create("Instance")
InstanceCheckerClass._Initial = CreateStandardInitial("Instance")
InstanceCheckerClass._TypeOf = {"Instance"}

local function _OfStructure(SelfRef, InstanceRoot, Context, SubTypes)
    -- Check all properties and children which should be in the Instance exist and the type check for each passes.
    for Key, Checker in SubTypes do
        local Value = TryGet(InstanceRoot, Key)
        local Success, SubMessage = Checker:_Check(Value, Context)

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

local function _IsA(_, InstanceRoot, _, InstanceIsA)
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

local function _OfChildType(_, InstanceRoot, Context, Checker)
    for _, Child in InstanceRoot:GetChildren() do
        local Success, Result = Checker:_Check(Child, Context)

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

local function _HasTag(_, InstanceRoot, _, Tag)
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

local function _HasAttribute(_, InstanceRoot, _, Attribute)
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

local function _CheckAttribute(_, InstanceRoot, Context, Attribute, Checker)
    local Success, SubMessage = (Checker :: any):_Check(InstanceRoot:GetAttribute(Attribute), Context)

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

local function _HasTags(_, InstanceRoot, _, Tags)
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

local function _HasAttributes(_, InstanceRoot, _, Attributes)
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

local function _CheckAttributes(_, InstanceRoot, Context, AttributeCheckers)
    for Attribute, Checker in AttributeCheckers do
        local Success, SubMessage = Checker:_Check(InstanceRoot:GetAttribute(Attribute), Context)

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

local function _IsDescendantOf(_, SubjectInstance, _, Instance)
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

local function _IsAncestorOf(_, SubjectInstance, _, Instance)
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

local function _HasChild(_, InstanceRoot, _, Name)
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

function InstanceCheckerClass:_Update()
    local SerializeScheme = self._SerializeScheme or "Full"

    if (SerializeScheme == "NetSync") then
        return {
            _Serialize = function(Buffer, _Value, _Context)
                local BufferContext = Buffer.Context

                if (BufferContext) then
                    BufferContext("Instance(NetSync)")
                    BufferContext()
                end
            end; 
            _Deserialize = function(_Buffer, _Context) end;
        }
    end

    local DynamicUInt = Number():Integer(32, false):Positive():Dynamic()
        local DynamicUIntDeserialize = DynamicUInt._Deserialize
        local DynamicUIntSerialize = DynamicUInt._Serialize

    local DefaultAny
    local LastAny

    local Attributes
        local AttributesDeserialize
        local AttributesSerialize

    local CacheableString = Cacheable(String())

    local Tags = Array(CacheableString)
        local TagsDeserialize = Tags._Deserialize
        local TagsSerialize = Tags._Serialize

    local function Init(Context)
        InitInstanceTypes()

        local UseAny = (Context and Context.UseAny or nil)

        if (UseAny == nil) then
            DefaultAny = DefaultAny or require(script.Parent.Parent.Core.ValueCache)((require(script.Parent.Parent.Roblox.Any) :: any)())
            UseAny = DefaultAny

            Context = Merge(Context or {}, {
                UseAny = DefaultAny;
            })
        end

        if (LastAny ~= UseAny) then
            LastAny = UseAny
            Attributes = Indexable():OfKeyType(CacheableString):OfValueType(UseAny)
                AttributesDeserialize = Attributes._Deserialize
                AttributesSerialize = Attributes._Serialize
        end
    end

    local function Serialize(Buffer, Value: Instance, Context)
        local BufferContext = Buffer.Context

        if (BufferContext) then
            BufferContext("Instance")
        end

        Context = Init(Context)

        local ClassName = Value.ClassName
        InstanceIDSerialize(Buffer, InstanceNameToID[ClassName], Context)

        -- Record properties in the form of [Count]([PropertyID][PropertyValue]...), which allows
        -- the skipping of unmodified properties.
        local PropertySerializers = InstanceNameToPropertiesSerializerInherited[ClassName]
        local ModifiedProperties = {}
        local Count = 0

        for Key, Serializer in PropertySerializers do
            if (IsPropertyModified(Value, Key)) then
                ModifiedProperties[Key] = true
                Count += 1
            end
        end

        DynamicUIntSerialize(Buffer, Count, Context)

        for Key, Serializer in PropertySerializers do
            if (ModifiedProperties[Key]) then
                local Success, PropertyValue = GetProperty(Value, Key)

                if (Success) then
                    PropertyIDSerialize(Buffer, PropertyNameToID[Key], Context)
                    Serializer._Serialize(Buffer, PropertyValue, Context)
                end
            end
        end

        -- Serialize attributes and tags.
        AttributesSerialize(Buffer, Value:GetAttributes(), Context)
        TagsSerialize(Buffer, Value:GetTags(), Context)

        -- Serialize each child using the context's Any, if defined, otherwise the Instance serializer.
        local ChildSerialize = (Context and Context.AnySerialize or Serialize)
        local Children = Value:GetChildren()
        DynamicUIntSerialize(Buffer, #Children, Context)

        for _, Child in Children do
            ChildSerialize(Buffer, Child, Context)
        end

        if (BufferContext) then
            BufferContext()
        end
    end

    -- Protects against circular references being nil. See Cacheable.
    local function InstantValueCapture(Result, Context)
        local CaptureInto = (Context and Context.CaptureInto or nil)

        if (CaptureInto) then
            CaptureInto[Context.CaptureValue] = Result
            Context.CaptureValue = nil
            Context.CaptureInto = nil
        end

        return Context
    end

    -- Todo: "apply" mode given a root Instance.
    local function Deserialize(Buffer, Context)
        Context = Init(Context)

        local ClassName = InstanceIDToName[InstanceIDDeserialize(Buffer, Context)]

        -- Assign properties. Custom "Creator" function is necessary because of MeshId not being assignable.
        local Creator = Creators[ClassName]
        local Regular = (Creator == nil)
        local Result = (Regular and CreateInstance(ClassName) or {})

        if (Regular) then
            Context = InstantValueCapture(Result, Context)
        end

        local PropertyDeserializers = InstanceNameToPropertiesSerializerInherited[ClassName]
        local PropertyCount = DynamicUIntDeserialize(Buffer, Context)

        for Index = 1, PropertyCount do
            local PropertyName = PropertyIDToName[PropertyIDDeserialize(Buffer, Context)]
            SetProperty(Result, PropertyName, PropertyDeserializers[PropertyName]._Deserialize(Buffer, Context))
        end

        if (Creator) then
            local Temp = Creator(Result)

            for Key, Value in Result do
                SetProperty(Temp, Key, Value)
            end

            Result = Temp
            Context = InstantValueCapture(Result, Context)
        end

        -- Apply attributes and tags.
        local Attributes = AttributesDeserialize(Buffer, Context)
        local Tags = TagsDeserialize(Buffer, Context)

        for Key, Value in Attributes do
            Result:SetAttribute(Key, Value)
        end

        for _, Tag in Tags do
            Result:AddTag(Tag)
        end

        -- Parent children to the Instance.
        local ChildrenSize = DynamicUIntDeserialize(Buffer, Context)
        local ChildDeserialize = (Context and Context.AnyDeserialize or Deserialize)

        for Index = 1, ChildrenSize do
            ChildDeserialize(Buffer, Context).Parent = Result
        end

        return Result
    end

    local IsA = self:GetConstraint("IsA")
        local IsAValue = (IsA and IsA[1] or nil)

    local function Sample(Context)
        InitInstanceTypes()
        
        if (IsAValue) then
            -- Todo: random subclass.
            return CreateInstance(IsAValue)
        end

        return CreateInstance(CreatableInstanceNameToID[Context.Random:NextInteger(1, #CreatableInstanceNameToID)])
    end

    return {
        _InitSerialize = Init;
        _InitDeserialize = Init;

        _Serialize = Serialize;
        _Deserialize = Deserialize;

        _Sample = Sample;
    }
end

InstanceCheckerClass.InitialConstraints = {InstanceCheckerClass.IsA, InstanceCheckerClass.OfStructure}
return InstanceChecker