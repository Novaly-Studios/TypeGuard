--!nonstrict
local Util = require(script:WaitForChild("Util"))
    local CreateStandardInitial = Util.CreateStandardInitial
    local AssertIsTypeBase = Util.AssertIsTypeBase
    local ExpectType = Util.ExpectType
    local Expect = Util.Expect

local TypeCheckers = script:WaitForChild("TypeCheckers")
    local Template = require(TypeCheckers:WaitForChild("_Template"))
        type SignatureTypeCheckerInternal = Template.SignatureTypeCheckerInternal
        type TypeCheckerConstructor<T, P...> = Template.TypeCheckerConstructor<T, P...>
        type SignatureTypeChecker = Template.SignatureTypeChecker
        type TypeChecker<ExtensionClass, Primitive> = Template.TypeChecker<ExtensionClass, Primitive>

local TypeGuard = {
    CreateTemplate = Template.Create;
    Template = Template;
}

--- This provides an easy way to create a type without any constraints, and just an initial check corresponding to Roblox's typeof.
function TypeGuard.FromTypeSample<T>(TypeName: string, Sample: T)
    ExpectType(TypeName, Expect.STRING, 1)

    local CheckerFunction, CheckerClass = Template.Create(TypeName)
    CheckerClass._Initial = CreateStandardInitial(TypeName)
    CheckerClass.InitialConstraint = CheckerClass.Equals

    type CustomTypeChecker = TypeChecker<CustomTypeChecker, T>
    return CheckerFunction :: TypeCheckerConstructor<CustomTypeChecker>
end

-- Complex type checker imports...
do
    TypeGuard.Number = require(TypeCheckers:WaitForChild("Number"))
    TypeGuard.number = TypeGuard.Number

    TypeGuard.String = require(TypeCheckers:WaitForChild("String"))
    TypeGuard.string = TypeGuard.String

    TypeGuard.Array = require(TypeCheckers:WaitForChild("Array"))
    TypeGuard.array = TypeGuard.Array

    TypeGuard.Object = require(TypeCheckers:WaitForChild("Object"))
    TypeGuard.object = TypeGuard.Object

    TypeGuard.Instance = require(TypeCheckers:WaitForChild("Instance"))
    TypeGuard.instance = TypeGuard.Instance

    TypeGuard.Enum = require(TypeCheckers:WaitForChild("Enum"))
    TypeGuard.enum = TypeGuard.Enum

    TypeGuard.Thread = require(TypeCheckers:WaitForChild("Thread"))
    TypeGuard.thread = TypeGuard.Thread

    TypeGuard.Any = require(TypeCheckers:WaitForChild("Any"))
    TypeGuard.any = TypeGuard.Any
end

-- Luau data types must be manually enumerated here because the LSP will not autosuggest them otherwise...
do
    local Any: any = {}
    local Sample = TypeGuard.FromTypeSample

    TypeGuard.Axes = Sample("Axes", Axes.new())
    TypeGuard.BrickColor = Sample("BrickColor", BrickColor.Black())
    TypeGuard.CatalogSearchParams = Sample("CatalogSearchParams", CatalogSearchParams.new())
    TypeGuard.CFrame = Sample("CFrame", CFrame.new())
    TypeGuard.Color3 = Sample("Color3", Color3.new())
    TypeGuard.ColorSequence = Sample("ColorSequence", ColorSequence.new(Color3.new()))
    TypeGuard.ColorSequenceKeypoint = Sample("ColorSequenceKeypoint", ColorSequenceKeypoint.new(0, Color3.new()))
    TypeGuard.DateTime = Sample("DateTime", DateTime.now())
    TypeGuard.DockWidgetPluginGuiInfo = Sample("DockWidgetPluginGuiInfo", DockWidgetPluginGuiInfo.new())
    TypeGuard.Enums = Sample("Enums", Enum)
    TypeGuard.Faces = Sample("Faces", Faces.new())
    TypeGuard.FloatCurveKey = Sample("FloatCurveKey", Any)
    TypeGuard.NumberRange = Sample("NumberRange", NumberRange.new(0, 0))
    TypeGuard.NumberSequence = Sample("NumberSequence", NumberSequence.new(1))
    TypeGuard.NumberSequenceKeypoint = Sample("NumberSequenceKeypoint", NumberSequenceKeypoint.new(1, 1))
    TypeGuard.OverlapParams = Sample("OverlapParams", OverlapParams.new())
    TypeGuard.PathWaypoint = Sample("PathWaypoint", PathWaypoint.new(Vector3.new(), Enum.PathWaypointAction.Jump))
    TypeGuard.PhysicalProperties = Sample("PhysicalProperties", PhysicalProperties.new(Enum.Material.Air))
    TypeGuard.Random = Sample("Random", Random.new())
    TypeGuard.Ray = Sample("Ray", Ray.new(Vector3.new(), Vector3.new()))
    TypeGuard.RaycastParams = Sample("RaycastParams", RaycastParams.new())
    TypeGuard.RaycastResult = Sample("RaycastResult", Any)
    TypeGuard.RBXScriptConnection = Sample("RBXScriptConnection", Instance.new("BindableEvent").Event:Connect(function() end))
    TypeGuard.RBXScriptSignal = Sample("RBXScriptSignal", Instance.new("BindableEvent").Event)
    TypeGuard.Rect = Sample("Rect", Rect.new(Vector2.new(), Vector2.new()))
    TypeGuard.Region3 = Sample("Region3", Region3.new(Vector3.new(), Vector3.new()))
    TypeGuard.Region3int16 = Sample("Region3int16", Region3int16.new(Vector3int16.new(), Vector3int16.new()))
    TypeGuard.TweenInfo = Sample("TweenInfo", TweenInfo.new())
    TypeGuard.UDim = Sample("UDim", UDim.new())
    TypeGuard.UDim2 = Sample("UDim2", UDim2.new())
    TypeGuard.Vector2 = Sample("Vector2", Vector2.new())
    TypeGuard.Vector2int16 = Sample("Vector2int16", Vector2int16.new(0, 0))
    TypeGuard.Vector3 = Sample("Vector3", Vector3.new())
    TypeGuard.Vector3int16 = Sample("Vector3int16", Vector3int16.new())

    -- Extra base Lua data types
    TypeGuard.Function = TypeGuard.FromTypeSample("function", function() end)
    TypeGuard.lfunction = TypeGuard.Function

    TypeGuard.Userdata = TypeGuard.FromTypeSample("userdata", newproxy(true))
    TypeGuard.luserdata = TypeGuard.Userdata

    TypeGuard.Nil = TypeGuard.FromTypeSample("nil", nil)
    TypeGuard.lnil = TypeGuard.Nil

    TypeGuard.Table = TypeGuard.FromTypeSample("table", {})
    TypeGuard.table = TypeGuard.Table

    TypeGuard.Boolean = TypeGuard.FromTypeSample("boolean", true)
    TypeGuard.boolean = TypeGuard.Boolean
end

-- Core functions...
do
    local ScriptNameToContextEnabled = {}

    local function _GetScript(): string
        local ScriptName = debug.info(3, "s") or "Unknown"
        local Splits = string.split(ScriptName, ".")
        return Splits[#Splits] or ScriptName
    end

    local ValidTypeChecker = TypeGuard.Object({
        _Check = TypeGuard.Function();
    })

    --- Creates a function which checks params as if they were a strict Array checker.
    function TypeGuard.Params(...: SignatureTypeChecker)
        local Args = {...}
        local ArgSize = #Args

        for Index, ParamChecker in Args do
            ValidTypeChecker:Assert(ParamChecker)
        end

        local Script = _GetScript()
        ScriptNameToContextEnabled[Script] = if (ScriptNameToContextEnabled[Script] ~= nil)
                                            then ScriptNameToContextEnabled[Script]
                                            else true

        return function(...)
            if (not ScriptNameToContextEnabled[Script]) then
                return
            end

            debug.profilebegin("TG.P")

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

            debug.profileend()
        end
    end
    TypeGuard.params = TypeGuard.Params

    local VariadicParams = TypeGuard.Params(ValidTypeChecker)
    --- Creates a function which checks variadic params against a single given TypeChecker.
    function TypeGuard.Variadic(CompareType: SignatureTypeChecker)
        VariadicParams(CompareType)

        local Script = _GetScript()
        ScriptNameToContextEnabled[Script] = if (ScriptNameToContextEnabled[Script] ~= nil)
                                            then ScriptNameToContextEnabled[Script]
                                            else true

        return function(...)
            if (not ScriptNameToContextEnabled[Script]) then
                return
            end

            debug.profilebegin("TG.V")

            local Size = select("#", ...)

            for Index = 1, Size do
                local Arg = select(Index, ...)
                local Success, Message = (CompareType :: SignatureTypeCheckerInternal):_Check(Arg)

                if (not Success) then
                    error(`Invalid argument #{Index} ({Message}).`)
                end
            end

            debug.profileend()
        end
    end
    TypeGuard.variadic = TypeGuard.Variadic

    local ParamsWithContextParams = TypeGuard.Variadic(ValidTypeChecker)
    --- Creates a function which checks params as if they were a strict Array checker, using context as the first param; context is passed down to functional constraint args.
    function TypeGuard.ParamsWithContext(...: SignatureTypeChecker)
        ParamsWithContextParams(...)

        local Args = {...}
        local ArgSize = #Args

        for Index, ParamChecker in Args do
            AssertIsTypeBase(ParamChecker, Index)
        end

        local Script = _GetScript()
        ScriptNameToContextEnabled[Script] = if (ScriptNameToContextEnabled[Script] ~= nil)
                                            then ScriptNameToContextEnabled[Script]
                                            else true

        return function(Context: any?, ...)
            if (not ScriptNameToContextEnabled[Script]) then
                return
            end

            debug.profilebegin("TG.P+")

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

            debug.profileend()
        end
    end
    TypeGuard.paramsWithContext = TypeGuard.ParamsWithContext

    local VariadicWithContextParams = TypeGuard.Params(ValidTypeChecker)
    --- Creates a function which checks variadic params against a single given TypeChecker, using context as the first param; context is passed down to functional constraint args.
    function TypeGuard.VariadicWithContext(CompareType: SignatureTypeChecker)
        VariadicWithContextParams(CompareType)

        local Script = _GetScript()
        ScriptNameToContextEnabled[Script] = if (ScriptNameToContextEnabled[Script] ~= nil)
                                            then ScriptNameToContextEnabled[Script]
                                            else true

        return function(Context: any?, ...)
            if (not ScriptNameToContextEnabled[Script]) then
                return
            end

            debug.profilebegin("TG.V+")

            local Size = select("#", ...)

            for Index = 1, Size do
                local Arg = select(Index, ...)
                local Success, Message = (CompareType :: SignatureTypeCheckerInternal):WithContext(Context):Check(Arg)

                if (not Success) then
                    error(`Invalid argument #{Index} ({Message}).`)
                end
            end

            debug.profileend()
        end
    end
    TypeGuard.variadicWithContext = TypeGuard.VariadicWithContext

    local WrapFunctionParamsParams1 = TypeGuard.Params(TypeGuard.Function())
    local WrapFunctionParamsParams2 = TypeGuard.Variadic(ValidTypeChecker)
    --- Wraps a function in a param checker function.
    function TypeGuard.WrapFunctionParams(Call: (...any) -> (...any), ...: SignatureTypeChecker)
        WrapFunctionParamsParams1(Call)
        WrapFunctionParamsParams2(...)

        for Index = 1, select("#", ...) do
            AssertIsTypeBase(select(Index, ...), Index)
        end

        local ParamChecker = TypeGuard.Params(...)

        return function(...)
            ParamChecker(...)
            return Call(...)
        end
    end
    TypeGuard.wrapFunctionParams = TypeGuard.WrapFunctionParams

    local WrapFunctionVariadicParams = TypeGuard.Params(TypeGuard.Function(), ValidTypeChecker)
    --- Wraps a function in a variadic param checker function.
    function TypeGuard.WrapFunctionVariadic(Call: (...any) -> (...any), VariadicParamType: SignatureTypeChecker)
        WrapFunctionVariadicParams(Call, VariadicParamType)

        local ParamChecker = TypeGuard.Variadic(VariadicParamType)

        return function(...)
            ParamChecker(...)
            return Call(...)
        end
    end
    TypeGuard.wrapFunctionVariadic = TypeGuard.WrapFunctionVariadic

    local Primitives = {
        ["nil"] = "Nil";
        ["string"] = "String";
        ["number"] = "Number";
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

                    if (Temp.Type == LastType) then
                        continue
                    end

                    Last = if (Last) then Temp:Or(Last) else Temp
                    LastType = Temp.Type
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
            return if (next(Structure)) then Base:OfStructure(Structure) else Base
        end

        if (Type == "EnumItem") then
            return TypeGuard.Enum(Subject)
        end

        local Constructor = TypeGuard[Type]

        if (not Constructor) then
            error("Unknown type: " .. Type)
        end

        return Constructor()
    end

    local FromTemplateParams = TypeGuard.Params(TypeGuard.Boolean():Optional())
    --- Creates a TypeChecker from a template table.
    function TypeGuard.FromTemplate(Subject: any, Strict: boolean?)
        FromTemplateParams(Strict)
        return _FromTemplate(Subject, Strict)
    end

    local SetContextEnabledParams = TypeGuard.Params(TypeGuard.String():IsAKeyIn(ScriptNameToContextEnabled), TypeGuard.Boolean())
    --- Certain scripts may want to disable type checking for a specific context for performance.
    function TypeGuard.SetContextEnabled(Name: string, Enabled: boolean)
        SetContextEnabledParams(Name, Enabled)
        ScriptNameToContextEnabled[Name] = Enabled
    end

    local SetCurrentContextEnabledParams = TypeGuard.Params(TypeGuard.Boolean())
    --- Sets the context for the calling script, which can be enabled or disabled with TypeGuard.SetContextEnabled.
    function TypeGuard.SetCurrentContextEnabled(Enabled: boolean)
        SetCurrentContextEnabledParams(Enabled)
        ScriptNameToContextEnabled[_GetScript()] = Enabled
    end
end

return TypeGuard