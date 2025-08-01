--!native
--!optimize 2

if (not script and Instance) then
    script = game:GetService("ReplicatedFirst").TypeGuard.Core.CompressibleCache
end

local Template = require(script.Parent.Parent._Template)
    type SignatureTypeChecker = Template.SignatureTypeChecker
    type TypeChecker<ExtensionClass, Primitive> = Template.TypeChecker<ExtensionClass, Primitive>

local TableUtil = require(script.Parent.Parent.Parent.TableUtil).WithFeatures()
    local Merge = TableUtil.Map.Merge

local Util = require(script.Parent.Parent.Util)
    local CreateStandardInitial = Util.CreateStandardInitial
    local AssertIsTypeBase = Util.AssertIsTypeBase
    local ExpectType = Util.ExpectType
    local Expect = Util.Expect

local Sequencer = require(script.Sequencer)
local Number = require(script.Parent.Number)

local DynamicUInt = Number():Integer(32, false):Positive():Dynamic()
    local DynamicUIntSerialize = DynamicUInt._Serialize
    local DynamicUIntDeserialize = DynamicUInt._Deserialize

type CompressibleCacheTypeChecker = TypeChecker<CompressibleCacheTypeChecker, nil> & {
    Using: ((self: CompressibleCacheTypeChecker, Serializer: SignatureTypeChecker, Config: Sequencer.Config) -> (CompressibleCacheTypeChecker));
};

--- This is used to quickly cache hashable values which might occur more than one time during serialization and deserialization
--- like commonly re-used strings for field names. Or to cache the first encounter with objects referenced multiple times.
local CompressibleCache: ((Serializer: SignatureTypeChecker?, Config: Sequencer.Config?) -> (CompressibleCacheTypeChecker)), CompressibleCacheClass = Template.Create("CompressibleCache")
CompressibleCacheClass._Initial = CreateStandardInitial("CompressibleCache")

function CompressibleCacheClass:Using(Serializer, Config)
    AssertIsTypeBase(Serializer, 1)

    if (Config) then
        ExpectType(Config, Expect.TABLE, 2)
    end

    return self:Modify({
        _Config = Config;
        _Using = Serializer;
    })
end

function CompressibleCacheClass:_Initial(Value)
    return self._Using:Check(Value)
end

function CompressibleCacheClass:_UpdateSerialize()
    local Serializer = self._Using

    if (not Serializer) then
        return
    end

    local CompressibleCacheOf = `CompressibleCache({Serializer.Name})`
    local Compressor = Sequencer(self._Config)
        local CompressorDecompress = Compressor.Decompress
        local CompressorCompress = Compressor.Compress

    local Deserialize = Serializer._Deserialize
    local Serialize = Serializer._Serialize

    return {
        _TypeOf = Serializer._TypeOf;
        Name = Serializer.Name;

        _Serialize = function(Buffer, Value, Context)
            local BufferContext = Buffer.Context

            if (BufferContext) then
                BufferContext(CompressibleCacheOf)
            end

            local StartPosition = Buffer.GetPosition()
            local CompressCaptureBuffer = Buffer.Constructor()
            Buffer.SetPosition(32)

            Serialize(Buffer, Value, Merge(Context or {}, {
                CompressCaptureBuffer = CompressCaptureBuffer; -- Pass CompressCaptureBuffer into _Serialize for the Compressible wrapped objects.
            }))

            -- Write offset on how to get to the compressed data.
            local CompressionStartPosition = Buffer.GetPosition()
            local Offset = CompressionStartPosition - StartPosition
            Buffer.WriteUInt(32, Offset)
            Buffer.SetPosition(CompressionStartPosition)

            -- Option: compress substring of buffer e.g. CompressorCompress(CompressCaptureBuffer.GetBuffer(), 0, CompressCaptureBuffer.GetPosition())
            local Compressed = CompressorCompress(CompressCaptureBuffer.GetClippedBuffer())
            local CompressedLength = buffer.len(Compressed)
            DynamicUIntSerialize(Buffer, CompressedLength, Context)
            Buffer.WriteBuffer(Compressed, 0, CompressedLength * 8)

            if (BufferContext) then
                BufferContext()
            end
        end;
        _Deserialize = function(Buffer, Context)
            local Offset = Buffer.ReadUInt(32)
            local DataStartPosition = Buffer.GetPosition()
            Buffer.IncrementPosition(Offset)

            local CompressedSize = DynamicUIntDeserialize(Buffer, Context)
            -- Option: decompress substring of buffer e.g. CompressorDecompress(Buffer.GetPosition(), CompressedSize)
            local CompressCaptureBuffer = CompressorDecompress(Buffer.ReadBuffer(CompressedSize * 8))
            Buffer.SetPosition(DataStartPosition)

            return Deserialize(Buffer, Merge(Context or {}, {
                CompressCaptureBuffer = Buffer.Constructor(CompressCaptureBuffer);
            }))
        end;
    }
end

CompressibleCacheClass.InitialConstraint = CompressibleCacheClass.Using
return CompressibleCache