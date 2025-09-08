--!native
--!optimize 2

if (not script and Instance) then
    script = game:GetService("ReplicatedFirst").TypeGuard.Core.Compressible
end

local Template = require(script.Parent.Parent._Template)
    type SignatureTypeChecker = Template.SignatureTypeChecker
    type TypeChecker<ExtensionClass, Primitive> = Template.TypeChecker<ExtensionClass, Primitive>

local Util = require(script.Parent.Parent.Util)
    local CreateStandardInitial = Util.CreateStandardInitial
    local AssertIsTypeBase = Util.AssertIsTypeBase

type CompressibleTypeChecker = TypeChecker<CompressibleTypeChecker, nil> & {
    Using: ((self: CompressibleTypeChecker, Serializer: SignatureTypeChecker) -> (CompressibleTypeChecker));
};

local Compressible: ((Serializer: SignatureTypeChecker) -> (CompressibleTypeChecker)), CompressibleClass = Template.Create("Compressible")
CompressibleClass._Initial = CreateStandardInitial("Compressible")
CompressibleClass._Compressible = true

function CompressibleClass:Using(Serializer)
    AssertIsTypeBase(Serializer, 1)

    return self:Modify({
        _Using = Serializer;
    })
end

function CompressibleClass:_Initial(Value)
    return self._Using:Check(Value)
end

function CompressibleClass:_Update()
    local Using = self._Using

    if (not Using) then
        return
    end

    local UsingSerialize = Using._Serialize
    local UsingDeserialize = Using._Deserialize

    local CompressibleOf = `Compressible({Using.Name})`

    return {
        _TypeOf = Using._TypeOf;
        Name = Using.Name;

        _Serialize = function(Buffer, Value, Context)
            local BufferContext = Buffer.Context

            if (BufferContext) then
                BufferContext(CompressibleOf)
            end

            UsingSerialize(Context.CompressCaptureBuffer or Buffer, Value, Context)

            if (BufferContext) then
                BufferContext()
            end
        end;
        _Deserialize = function(Buffer, Context)
            return UsingDeserialize(Context.CompressCaptureBuffer or Buffer, Context)
        end
    }
end

local Original = CompressibleClass.RemapDeep
function CompressibleClass:RemapDeep(Type, Mapper, Recursive)
    local Copy = Original(self, Type, Mapper, Recursive)
        local Using = Copy._Using

    if (Using and Using.RemapDeep) then
        Copy = Copy:Modify({
            _Using = Mapper(Using:RemapDeep(Type, Mapper, Recursive));
        })
    end

    return Copy
end

CompressibleClass.InitialConstraint = CompressibleClass.Using
return Compressible