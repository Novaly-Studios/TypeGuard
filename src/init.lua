--!native
--!optimize 2
--!nonstrict

-- Allows easy command bar paste.
if (not script and Instance) then
    script = game:GetService("ReplicatedFirst").TypeGuard
end

local Util = require(script.Util)
    local CreateStandardInitial = Util.CreateStandardInitial
    local AssertIsTypeBase = Util.AssertIsTypeBase
    local ExpectType = Util.ExpectType
    local Expect = Util.Expect

local Roblox = script.Roblox
local Core = script.Core

local Template = require(script._Template)
    type SignatureTypeCheckerInternal = Template.SignatureTypeCheckerInternal
    type TypeCheckerConstructor<T, P...> = Template.TypeCheckerConstructor<T, P...>
    type TypeChecker<ExtensionClass, Primitive> = Template.TypeChecker<ExtensionClass, Primitive>
    
export type SignatureTypeChecker = Template.SignatureTypeChecker

local TypeGuard = {
    CreateTemplate = Template.Create;
    Template = Template;
    Util = Util;
}

--- This provides an easy way to create a type without any constraints, and just an initial check corresponding to Roblox's typeof.
local FromTypeSample = function(TypeName, Sample, Serialize, Deserialize)
    ExpectType(TypeName, Expect.STRING, 1)

    local CheckerFunction, CheckerClass = Template.Create(TypeName)
    CheckerClass._Initial = CreateStandardInitial(TypeName)
    CheckerClass.InitialConstraint = CheckerClass.Equals

    if (Serialize) then
        if (type(Serialize) == "table") then
            CheckerClass._Serialize = Serialize._Serialize
            CheckerClass._Deserialize = Serialize._Deserialize
        else
            CheckerClass._Serialize = Serialize
            CheckerClass._Deserialize = Deserialize
        end
    end

    return CheckerFunction
end ::
    (<T>(TypeName: string, Sample: T, Serialize: ((Util.Serializer, T) -> ()), Deserialize: ((Util.Serializer) -> T)) -> (TypeCheckerConstructor<TypeChecker<any, T>>)) &
    (<T>(TypeName: string, Sample: T, Serialize: TypeChecker<any, T>) -> (TypeCheckerConstructor<TypeChecker<any, T>>)) &
    (<T>(TypeName: string, Sample: T) -> (TypeCheckerConstructor<TypeChecker<any, T>>))

TypeGuard.FromTypeSample = FromTypeSample

-- Complex type checker imports...
do
    TypeGuard.CompressibleCache = require(Core.CompressibleCache)
    TypeGuard.Compressible = require(Core.Compressible)
    TypeGuard.ValueCache = require(Core.ValueCache)
    TypeGuard.Versioned = require(Core.Versioned)
    TypeGuard.Cacheable = require(Core.Cacheable)
    TypeGuard.Indexable = require(Core.Indexable)
    TypeGuard.Function = require(Core.Function)
    TypeGuard.Userdata = require(Core.Userdata)
    TypeGuard.Optional = require(Core.Optional)
    TypeGuard.Boolean = require(Core.Boolean)
    TypeGuard.BaseAny = require(Core.BaseAny)
    TypeGuard.Object = require(Core.Indexable)
    TypeGuard.Number = require(Core.Number)
    TypeGuard.String = require(Core.String)
    TypeGuard.Thread = require(Core.Thread)
    TypeGuard.Buffer = require(Core.Buffer)
    TypeGuard.Array = require(Core.Array)
    TypeGuard.Nil = require(Core.Nil)
    TypeGuard.Or = require(Core.Or)
end

-- Luau data types must be manually enumerated here because the LSP will not autosuggest them otherwise...
do
    -- Roblox Luau data types.
    TypeGuard.BrickColor = require(Roblox.BrickColor)
    TypeGuard.CFrame = require(Roblox.CFrame)
    TypeGuard.Color3 = require(Roblox.Color3)
    TypeGuard.ColorSequence = require(Roblox.ColorSequence)
    TypeGuard.ColorSequenceKeypoint = require(Roblox.ColorSequenceKeypoint)
    TypeGuard.Enum = require(Roblox.Enum)
    TypeGuard.Instance = require(Roblox.Instance)
    TypeGuard.NumberSequence = require(Roblox.NumberSequence)
    TypeGuard.UDim = require(Roblox.UDim)
    TypeGuard.UDim2 = require(Roblox.UDim2)
    TypeGuard.Vector2 = require(Roblox.Vector2)
    TypeGuard.Vector3 = require(Roblox.Vector3)
    TypeGuard.TweenInfo = require(Roblox.TweenInfo)
    TypeGuard.Ray = require(Roblox.Ray)
    TypeGuard.Any = require(Roblox.Any)
    TypeGuard.NumberSequenceKeypoint = require(Roblox.NumberSequenceKeypoint)
    TypeGuard.NumberSequence = require(Roblox.NumberSequence)
    TypeGuard.NumberRange = require(Roblox.NumberRange)
    TypeGuard.SharedTable = require(Roblox.SharedTable)
    TypeGuard.Axes = require(Roblox.Axes)
    TypeGuard.CatalogSearchParams = require(Roblox.CatalogSearchParams)
    TypeGuard.Content = require(Roblox.Content)
    TypeGuard.DateTime = require(Roblox.DateTime)
    TypeGuard.Faces = require(Roblox.Faces)
    TypeGuard.FloatCurveKey = require(Roblox.FloatCurveKey)
    TypeGuard.Font = require(Roblox.Font)
    TypeGuard.OverlapParams = require(Roblox.OverlapParams)
    TypeGuard.Path2DControlPoint = require(Roblox.Path2DControlPoint)
    TypeGuard.PathWaypoint = require(Roblox.PathWaypoint)
    TypeGuard.PhysicalProperties = require(Roblox.PhysicalProperties)
    TypeGuard.RaycastParams = require(Roblox.RaycastParams)
    TypeGuard.Rect = require(Roblox.Rect)
    TypeGuard.Region3 = require(Roblox.Region3)
    TypeGuard.RotationCurveKey = require(Roblox.RotationCurveKey)
    TypeGuard.RBXScriptConnection = require(Roblox.RBXScriptConnection)
    TypeGuard.RBXScriptSignal = require(Roblox.RBXScriptSignal)
end

-- Core functions...
do
    local ValidTypeChecker = TypeGuard.Object({
        -- _Check = TypeGuard.Function();
        _TC = TypeGuard.Boolean();
    })

    TypeGuard.Serializers = Util.Serializers

    --- Creates a function which checks params as if they were a strict Array checker.
    function TypeGuard.Params(...: SignatureTypeChecker)
        local Args = {...}
        local ArgSize = #Args

        for Index, ParamChecker in Args do
            ValidTypeChecker:Assert(ParamChecker)
        end

        return function(...)
            local Size = select("#", ...)

            if (Size > ArgSize) then
                error(`Expected {ArgSize} argument{(ArgSize == 1 and "" or "s")}, got {Size}.`)
            end

            for Index, Value in Args do
                local Arg = select(Index, ...)
                local Success, Message = Value:_Check(Arg)

                if (not Success) then
                    error(`Invalid argument #{Index} ({Message}).`)
                end
            end
        end
    end

    local VariadicParams = TypeGuard.Params(ValidTypeChecker)
    --- Creates a function which checks variadic params against a single given TypeChecker.
    function TypeGuard.Variadic<T>(CompareType: TypeChecker<any, T>): ((...T) -> ())
        VariadicParams(CompareType)

        return function(...)
            local Size = select("#", ...)

            for Index = 1, Size do
                local Arg = select(Index, ...)
                local Success, Message = (CompareType :: any):_Check(Arg)

                if (not Success) then
                    error(`Invalid argument #{Index} ({Message}).`)
                end
            end
        end
    end

    local ParamsWithContextParams = TypeGuard.Variadic(ValidTypeChecker)
    --- Creates a function which checks params as if they were a strict Array checker, using context as the first param; context is passed down to functional constraint args.
    function TypeGuard.ParamsWithContext(...: SignatureTypeChecker)
        ParamsWithContextParams(...)

        local Args = {...}
        local ArgSize = #Args

        for Index, ParamChecker in Args do
            AssertIsTypeBase(ParamChecker, Index)
        end

        return function(Context: any?, ...)
            local Size = select("#", ...)

            if (Size > ArgSize) then
                error(`Expected {ArgSize} argument{(ArgSize == 1 and "" or "s")}, got {Size}.`)
            end

            for Index, Value in Args do
                local Arg = select(Index, ...)
                local Success, Message = Value:WithContext(Context):Check(Arg)

                if (not Success) then
                    error(`Invalid argument #{Index} ({Message}).`)
                end
            end
        end
    end

    local VariadicWithContextParams = TypeGuard.Params(ValidTypeChecker)
    --- Creates a function which checks variadic params against a single given TypeChecker, using context as the first param; context is passed down to functional constraint args.
    function TypeGuard.VariadicWithContext<T>(CompareType: TypeChecker<any, T>): ((any?, ...T) -> ())
        VariadicWithContextParams(CompareType)

        return function(Context, ...)
            local Size = select("#", ...)

            for Index = 1, Size do
                local Arg = select(Index, ...)
                local Success, Message = CompareType:WithContext(Context):Check(Arg)

                if (not Success) then
                    error(`Invalid argument #{Index} ({Message}).`)
                end
            end
        end
    end

    local Primitives = {
        ["nil"] = "Nil";
        ["string"] = "String";
        ["number"] = "Number";
        ["buffer"] = "Buffer";
        ["thread"] = "Thread";
        ["boolean"] = "Boolean";
        ["function"] = "Function";
        ["userdata"] = "Userdata";
    }

    local function _FromTemplate(Subject: any, Strict: boolean?)
        local Type = typeof(Subject)
        Type = Primitives[Type] or Type

        if (Type == "table") then
            if (Subject[1]) then
                local Last
                local LastType = ""

                for Key, Value in Subject do
                    local Temp = _FromTemplate(Value, Strict)

                    if (Temp.Name == LastType) then
                        continue
                    end

                    Last = if (Last) then TypeGuard.Or(Temp, Last) else Temp
                    LastType = Temp.Name
                end

                return TypeGuard.Array(Strict and Last:Strict() or Last)
            else
                local Result = {}

                for Key, Value in Subject do
                    Result[Key] = _FromTemplate(Value, Strict)
                end

                local Temp = TypeGuard.Object(Result)
                return Strict and Temp:Strict() or Temp
            end
        end

        if (Type == "Instance") then
            local Structure = {}

            for _, Child in Subject:GetChildren() do
                Structure[Child.Name] = _FromTemplate(Child, Strict)
            end

            local Base = TypeGuard.Instance(Subject.ClassName)
            Base = Strict and Base:Strict() or Base
            return (next(Structure) ~= nil and Base:OfStructure(Structure) or Base)
        end

        if (Type == "EnumItem") then
            return TypeGuard.Enum(Subject)
        end

        local Constructor = TypeGuard[Type]

        if (not Constructor) then
            error(`Unknown type: {Type}`)
        end

        return Constructor()
    end

    local FromTemplateParams = TypeGuard.Params(TypeGuard.Or(TypeGuard.Boolean(), TypeGuard.Nil()))
    --- Creates a TypeChecker from a template table.
    function TypeGuard.FromTemplate(Subject: any, Strict: boolean?)
        FromTemplateParams(Strict)
        return _FromTemplate(Subject, Strict)
    end
end

return table.freeze(TypeGuard)