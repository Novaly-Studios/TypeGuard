return function()
    local Union = require(script.Parent.Union)
    local FromValues = require(script.Parent.FromValues)

    describe("Set/Union", function()
        it("should combine two empty sets into an empty set", function()
            local Result = Union({}, {})
            expect(next(Result)).never.to.be.ok()
        end)

        it("should return A for A union B where B is empty" , function()
            local A = FromValues({"x", "y", "z"})
            local B = FromValues({})

            expect(Union(A, B)).to.equal(A)
        end)

        it("should return B for A union B where A is empty" , function()
            local A = FromValues({})
            local B = FromValues({"x", "y", "z"})

            expect(Union(A, B)).to.equal(B)
        end)

        it("should return an equal set for two equivalent sets", function()
            local A = FromValues({"x", "y", "z"})
            local B = FromValues({"x", "y", "z"})

            for Key in A do
                expect(B[Key]).to.equal(A[Key])
            end

            for Key in B do
                expect(A[Key]).to.equal(B[Key])
            end
        end)

        it("should return a union of two sets", function()
            local A = FromValues({"X", "Y", "Z"})
            local B = FromValues({"P", "Q", "R"})
            local Merge = Union(A, B)

            expect(Merge.X).to.be.ok()
            expect(Merge.Y).to.be.ok()
            expect(Merge.Z).to.be.ok()
            expect(Merge.P).to.be.ok()
            expect(Merge.Q).to.be.ok()
            expect(Merge.R).to.be.ok()
        end)
    end)
end