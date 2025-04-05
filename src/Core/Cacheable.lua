--!native
--!optimize 2

if (not script and Instance) then
    script = game:GetService("ReplicatedFirst").TypeGuard.Core.Cacheable
end

local Template = require(script.Parent.Parent._Template)
    type SignatureTypeChecker = Template.SignatureTypeChecker
    type TypeChecker<ExtensionClass, Primitive> = Template.TypeChecker<ExtensionClass, Primitive>

local TableUtil = require(script.Parent.Parent.Parent.TableUtil).WithFeatures()
    local Merge = TableUtil.Map.Merge

local Util = require(script.Parent.Parent.Util)
    local CreateStandardInitial = Util.CreateStandardInitial
    local AssertIsTypeBase = Util.AssertIsTypeBase

local Number = require(script.Parent.Number)

type CacheableTypeChecker = TypeChecker<CacheableTypeChecker, nil> & {
    Using: ((self: CacheableTypeChecker, Serializer: SignatureTypeChecker) -> (CacheableTypeChecker));
};

local Cacheable: ((Serializer: SignatureTypeChecker) -> (CacheableTypeChecker)), CacheableCheckerClass = Template.Create("Cacheable")
CacheableCheckerClass._Initial = CreateStandardInitial("Cacheable")
CacheableCheckerClass._Cacheable = true

function CacheableCheckerClass:Using(Serializer)
    AssertIsTypeBase(Serializer, 1)

    return self:Modify({
        _Using = Serializer;
    })
end

function CacheableCheckerClass:_Initial(Value)
    return self._Using:Check(Value)
end

function CacheableCheckerClass:_UpdateSerialize()
    local Using = self._Using

    if (not Using) then
        return
    end

    local UsingDeserialize = Using._Deserialize
    local UsingSerialize = Using._Serialize

    local DynamicUInt = Number():Integer(32, false):Positive():Dynamic()
        local DynamicUIntSerialize = DynamicUInt._Serialize
        local DynamicUIntDeserialize = DynamicUInt._Deserialize

    local CacheableOf = `Cacheable({Using.Name})`

    return {
        _TypeOf = Using._TypeOf;
        Name = Using.Name;

        -- Idea here is for each value wrapped in a Cacheable, it will insert that value into
        -- a value-to-index association and increment the index by 1, and serialize the index.
        -- It'll also prefix with a single bit signifying if the value was encountered before
        -- so deserialization knows whether to pull the next value from its inverse cache -
        -- index-to-value - or deserialize the current value and store it in the inverse cache.
        _Serialize = function(Buffer, Value, Context)
            local BufferContext = Buffer.Context
            BufferContext(CacheableOf)

            local ValueToIndex = (Context and Context.ValueToIndex or nil)

            if (ValueToIndex) then
                -- ValueCache can define a "persistent cache" which can be updated between
                -- multiple serializations. That allows for long term caching of values for
                -- networking.
                local GetIndexFromValue = Context.GetIndexFromValue

                if (GetIndexFromValue) then
                    local Index = GetIndexFromValue(Value)

                    if (Index) then
                        -- 2: value was found in the persistent cache.
                        Buffer.WriteUInt(2, 2)
                        DynamicUIntSerialize(Buffer, Index, Context)
                        BufferContext()
                        return
                    end
                end

                -- No persistent cache -> store in local cache.
                local FoundIndex = ValueToIndex[Value]

                if (FoundIndex) then
                    -- 1: value has been encountered before.
                    -- Todo: can use relative pointers in future to compress more?
                    Buffer.WriteUInt(2, 1)
                    DynamicUIntSerialize(Buffer, FoundIndex, Context)
                else
                    -- 0: value has not been encountered before.
                    local CacheIndex = Context.CacheIndex
                    ValueToIndex[Value] = CacheIndex
                    Context.CacheIndex = CacheIndex + 1
                    Buffer.WriteUInt(2, 0)
                    UsingSerialize(Buffer, Value, Context)
                end
            else
                UsingSerialize(Buffer, Value, Context)
            end

            BufferContext()
        end;
        _Deserialize = function(Buffer, Context)
            local IndexToValue = (Context and Context.IndexToValue or nil)

            if (IndexToValue) then
                local Tag = Buffer.ReadUInt(2)

                if (Tag == 0) then -- 0 will usually be most common condition so keep at top for performance.
                    local Position = Context.CacheIndex
                    Context.CacheIndex = Position + 1

                    local Value = UsingDeserialize(Buffer, Merge(Context, {
                        -- This immediately inserts the value into IndexToValue before recursing deeper,
                        -- solving cyclic references. Value is only initialized at this point, but it will
                        -- be filled during recursion while still being referenced in the cycle.
                        CaptureValue = Position;
                        CaptureInto = IndexToValue;
                    }))

                    -- Not everything captures, so manually insert when finished too.
                    IndexToValue[Position] = Value
                    return Value
                elseif (Tag == 1) then
                    return IndexToValue[DynamicUIntDeserialize(Buffer, Context)]
                else -- Tag == 2
                    return Context.GetValueFromIndex(DynamicUIntDeserialize(Buffer, Context))
                end
            end

            return UsingDeserialize(Buffer, Context)
        end;
    }
end

local Original = CacheableCheckerClass.RemapDeep
function CacheableCheckerClass:RemapDeep(Type, Mapper, Recursive)
    local Copy = Original(self, Type, Mapper, Recursive)
        local Using = Copy._Using

    if (Using and Using.RemapDeep) then
        Copy = Copy:Modify({
            _Using = Mapper(Using:RemapDeep(Type, Mapper, Recursive));
        })
    end

    return Copy
end

CacheableCheckerClass.InitialConstraint = CacheableCheckerClass.Using
return Cacheable