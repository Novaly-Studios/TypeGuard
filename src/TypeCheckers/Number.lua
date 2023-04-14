local Template = require(script.Parent:WaitForChild("_Template"))
    type TypeCheckerConstructor<T, P...> = Template.TypeCheckerConstructor<T, P...>
    type TypeChecker<ExtensionClass, Primitive> = Template.TypeChecker<ExtensionClass, Primitive>
    type SelfReturn<T, P...> = Template.SelfReturn<T, P...>

local Util = require(script.Parent.Parent:WaitForChild("Util"))
    local CreateStandardInitial = Util.CreateStandardInitial
    local ExpectType = Util.ExpectType
    local Expect = Util.Expect

type NumberTypeChecker = TypeChecker<NumberTypeChecker, number> & {
    RangeInclusive: SelfReturn<NumberTypeChecker, number | (any?) -> number, number | (any?) -> number>;
    RangeExclusive: SelfReturn<NumberTypeChecker, number | (any?) -> number, number | (any?) -> number>;
    IsInfinite: SelfReturn<NumberTypeChecker>;
    Positive: SelfReturn<NumberTypeChecker>;
    Negative: SelfReturn<NumberTypeChecker>;
    IsClose: SelfReturn<NumberTypeChecker, number | (any?) -> number, number | (any?) -> number>;
    Integer: SelfReturn<NumberTypeChecker>;
    Decimal: SelfReturn<NumberTypeChecker>;
    IsNaN: SelfReturn<NumberTypeChecker>;
};

local Number: TypeCheckerConstructor<NumberTypeChecker, number?, number?>, NumberClass = Template.Create("Number")
NumberClass._Initial = CreateStandardInitial("number")

--- Checks if the value is whole.
function NumberClass:Integer()
    return self:_AddConstraint(true, "Integer", function(_, Item)
        if (Item % 1 == 0) then
            return true
        end

        return false, `Expected integer form, got {Item}`
    end)
end

--- Checks if the number is not whole.
function NumberClass:Decimal()
    return self:_AddConstraint(true, "Decimal", function(_, Item)
        if (Item % 1 ~= 0) then
            return true
        end

        return false, `Expected decimal form, got {Item}`
    end)
end

--- Ensures a number is between or equal to a minimum and maximum value. Can also function as "equals" - useful for this being used as the InitialConstraint.
function NumberClass:RangeInclusive(Min, Max)
    ExpectType(Min, Expect.NUMBER_OR_FUNCTION, 1)
    Max = (Max == nil and Min or Max)
    ExpectType(Max, Expect.NUMBER_OR_FUNCTION, 2)

    if (Max == Min) then
        return self:Equals(Min)
    end

    return self:GreaterThanOrEqualTo(Min):LessThanOrEqualTo(Max)
end

--- Ensures a number is between but not equal to a minimum and maximum value.
function NumberClass:RangeExclusive(Min, Max)
    return self:GreaterThan(Min):LessThan(Max)
end

--- Checks the number is positive.
function NumberClass:Positive()
    return self:_AddConstraint(true, "Positive", function(_, Item)
        if (Item < 0) then
            return false, `Expected positive number, got {Item}`
        end

        return true
    end)
end

--- Checks the number is negative.
function NumberClass:Negative()
    return self:_AddConstraint(true, "Negative", function(_, Item)
        if (Item >= 0) then
            return false, `Expected negative number, got {Item}`
        end

        return true
    end)
end

--- Checks if the number is NaN.
function NumberClass:IsNaN()
    return self:_AddConstraint(true, "IsNaN", function(_, Item)
        if (Item ~= Item) then
            return true
        end

        return false, `Expected NaN, got {Item}`
    end)
end

--- Checks if the number is infinite.
function NumberClass:IsInfinite()
    return self:_AddConstraint(true, "IsInfinite", function(_, Item)
        if (Item == math.huge or Item == -math.huge) then
            return true
        end

        return false, `Expected infinite, got {Item}`
    end)
end

--- Checks if the number is close to another.
function NumberClass:IsClose(CloseTo, Tolerance)
    ExpectType(CloseTo, Expect.NUMBER_OR_FUNCTION, 1)
    Tolerance = Tolerance or 0.00001

    return self:_AddConstraint(true, "IsClose", function(_, NumberValue, CloseTo, Tolerance)
        if (math.abs(NumberValue - CloseTo) < Tolerance) then
            return true
        end

        return false, `Expected {CloseTo} +/- {Tolerance}, got {NumberValue}`
    end, CloseTo, Tolerance)
end

NumberClass.InitialConstraint = NumberClass.RangeInclusive

return Number