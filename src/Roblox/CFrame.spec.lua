local function anyfn(...) return ({} :: any) end
it = it or anyfn
expect = expect or anyfn
describe = describe or anyfn

return function()
    local GetValues = require(script.Parent.Parent.Core._TestValues)
    local TypeGuard = require(script.Parent.Parent)
    local Base = TypeGuard.CFrame()

    describe("Init", function()
        it("should reject non-CFrames", function()
            for _, Value in GetValues("CFrame") do
                expect(Base:Check(Value)).to.equal(false)
            end
        end)

        it("should accept CFrames", function()
            expect(Base:Check(CFrame.new(1, 1, 1))).to.equal(true)
        end)
    end)

    describe("Serialize, Deserialize", function()
        it("should correctly serialize & deserialize CFrames (approx)", function()
            local Test1 = CFrame.new(1.347834782348, 2, 3) * CFrame.Angles(math.rad(20), math.rad(30), math.rad(40))
            local X1, Y1, Z1, R001, R011, R021, R101, R111, R121, R201, R211, R221 = Test1:GetComponents()
            local Result = Base:Deserialize(Base:Serialize(Test1))
            local X2, Y2, Z2, R002, R012, R022, R102, R112, R122, R202, R212, R222 = Result:GetComponents()
            expect(X1).to.equal(X2)
            expect(Y1).to.equal(Y2)
            expect(Z1).to.equal(Z2)
            expect(R001).to.be.near(R002, 0.001)
            expect(R011).to.be.near(R012, 0.001)
            expect(R021).to.be.near(R022, 0.001)
            expect(R101).to.be.near(R102, 0.001)
            expect(R111).to.be.near(R112, 0.001)
            expect(R121).to.be.near(R122, 0.001)
            expect(R201).to.be.near(R202, 0.001)
            expect(R211).to.be.near(R212, 0.001)
            expect(R221).to.be.near(R222, 0.001)
        end)
    end)
end