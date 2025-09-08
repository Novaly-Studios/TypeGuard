--!native
--!optimize 2

if (not script and Instance) then
    script = game:GetService("ReplicatedFirst").TypeGuard.Core.Versioned
end

local Template = require(script.Parent.Parent._Template)
    type SignatureTypeChecker = Template.SignatureTypeChecker
    type TypeChecker<ExtensionClass, Primitive> = Template.TypeChecker<ExtensionClass, Primitive>

local Util = require(script.Parent.Parent.Util)
    local CreateStandardInitial = Util.CreateStandardInitial
    local ExpectType = Util.ExpectType
    local Expect = Util.Expect

type VersionedTypeChecker = TypeChecker<VersionedTypeChecker, nil> & {
    DefineVersions: ((self: VersionedTypeChecker, Versions: {SignatureTypeChecker}) -> (VersionedTypeChecker));
};

--- This is used to create different versions of a type serializer and have it forward compatible.
local Versioned: (({SignatureTypeChecker}?) -> (VersionedTypeChecker)), VersionedCheckerClass = Template.Create("Versioned")
VersionedCheckerClass._Initial = CreateStandardInitial("Versioned")

function VersionedCheckerClass:DefineVersions(Versions)
    ExpectType(Versions, Expect.TABLE, 1)
    assert(#Versions <= 0xFFFF, "Version must be at most 16 bits")

    return self:Modify({
        _DefineVersions = Versions;
    })
end

function VersionedCheckerClass:_Initial()
    return true
end

function VersionedCheckerClass:_Update()
    local Versions = self._DefineVersions

    if (not Versions) then
        return {
            _Serialize = function(_Buffer, _Value, _Context)
                error("No versions defined")
            end;
            _Deserialize = function(_Buffer, _Context)
                error("No versions defined")
            end;
        }
    end

    local VersionsCount = #Versions
    local LatestVersion = Versions[VersionsCount]
        local LatestVersionSerialize = LatestVersion._Serialize

    local VersionedString = `Versioned({VersionsCount})`

    return {
        _Serialize = function(Buffer, Value, Context)
            local BufferContext = Buffer.Context

            if (BufferContext) then
                BufferContext(VersionedString)
            end

            Buffer.WriteUInt(16, VersionsCount)
            LatestVersionSerialize(Buffer, Value, Context)

            if (BufferContext) then
                BufferContext()
            end
        end;
        _Deserialize = function(Buffer, Context)
            return Versions[Buffer.ReadUInt(16)]._Deserialize(Buffer, Context)
        end;
    }
end

VersionedCheckerClass.InitialConstraint = VersionedCheckerClass.DefineVersions

return Versioned