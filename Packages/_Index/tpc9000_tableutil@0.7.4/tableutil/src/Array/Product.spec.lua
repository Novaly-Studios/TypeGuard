return function()
    local Product = require(script.Parent.Parent).Array.Product

    local function Check(Test, Index, Expected)
        local Pairing = Test[Index]
        expect(Pairing).to.be.a("table")
        expect(#Pairing).to.equal(#Expected)
        for Index, Value in Expected do
            expect(Pairing[Index]).to.equal(Value)
        end
    end

    describe("Array/Product", function()
        it("should return an empty table for no elements", function()
            expect(next(Product({}, 1))).to.equal(nil)
            expect(next(Product({}, 2))).to.equal(nil)
            expect(next(Product({}, 3))).to.equal(nil)
        end)

        it("should return a single element list for a single element", function()
            local Test = Product({1}, 1)
            expect(Test).to.be.a("table")
            expect(#Test).to.equal(1)
            expect(Test[1]).to.be.a("table")
            expect(#Test[1]).to.equal(1)
            expect(Test[1][1]).to.equal(1)

            Test = Product({1}, 3)
            expect(Test).to.be.a("table")
            expect(#Test).to.equal(1)
            expect(Test[1]).to.be.a("table")
            expect(#Test[1]).to.equal(3)
            expect(Test[1][1]).to.equal(1)
            expect(Test[1][2]).to.equal(1)
            expect(Test[1][3]).to.equal(1)
        end)

        it("should compute the Cartesian product of two values", function()
            local Test = Product({1, 2}, 2)
            expect(Test).to.be.a("table")
            expect(#Test).to.equal(4)
            Check(Test, 1, {1, 1})
            Check(Test, 2, {1, 2})
            Check(Test, 3, {2, 1})
            Check(Test, 4, {2, 2})
        end)

        it("should compute the 3D cartesian product of two values", function()
            local Test = Product({1, 2}, 3)
            expect(Test).to.be.a("table")
            expect(#Test).to.equal(8)
            Check(Test, 1, {1, 1, 1})
            Check(Test, 2, {1, 1, 2})
            Check(Test, 3, {1, 2, 1})
            Check(Test, 4, {1, 2, 2})
            Check(Test, 5, {2, 1, 1})
            Check(Test, 6, {2, 1, 2})
            Check(Test, 7, {2, 2, 1})
            Check(Test, 8, {2, 2, 2})
        end)
    end)
end