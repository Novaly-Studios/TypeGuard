local function anyfn(...) return ({} :: any) end
it = it or anyfn
expect = expect or anyfn
describe = describe or anyfn

return function()
    local TypeGuard = require(script.Parent.Parent)
    local Base = TypeGuard.Thread()

    describe("Init", function()
        it("should reject non-thread values", function()
            expect(Base:Check(1)).to.equal(false)
            expect(Base:Check(function() end)).to.equal(false)
            expect(Base:Check({})).to.equal(false)
        end)

        it("should accept thread values", function()
            expect(Base:Check(coroutine.create(function() end))).to.equal(true)
        end)
    end)

    describe("HasStatus", function()
        it("should accept running threads given 'running'", function()
            local Thread = coroutine.running()

            expect(Base:HasStatus("suspended"):Check(Thread)).to.equal(false)
            expect(Base:HasStatus("running"):Check(Thread)).to.equal(true)
            expect(Base:HasStatus("normal"):Check(Thread)).to.equal(false)
            expect(Base:HasStatus("dead"):Check(Thread)).to.equal(false)

            expect(Base:HasStatus(function() return "suspended" end):Check(Thread)).to.equal(false)
            expect(Base:HasStatus(function() return "running" end):Check(Thread)).to.equal(true)
            expect(Base:HasStatus(function() return "normal" end):Check(Thread)).to.equal(false)
            expect(Base:HasStatus(function() return "dead" end):Check(Thread)).to.equal(false)
        end)

        it("should accept suspended threads given 'suspended'", function()
            local Thread = task.spawn(function()
                task.wait(1)
            end)

            expect(Base:HasStatus("suspended"):Check(Thread)).to.equal(true)
            expect(Base:HasStatus("running"):Check(Thread)).to.equal(false)
            expect(Base:HasStatus("normal"):Check(Thread)).to.equal(false)
            expect(Base:HasStatus("dead"):Check(Thread)).to.equal(false)

            expect(Base:HasStatus(function() return "suspended" end):Check(Thread)).to.equal(true)
            expect(Base:HasStatus(function() return "running" end):Check(Thread)).to.equal(false)
            expect(Base:HasStatus(function() return "normal" end):Check(Thread)).to.equal(false)
            expect(Base:HasStatus(function() return "dead" end):Check(Thread)).to.equal(false)
        end)

        it("should accept threads given 'dead'", function()
            local Thread = task.spawn(function() end)

            expect(Base:HasStatus("suspended"):Check(Thread)).to.equal(false)
            expect(Base:HasStatus("running"):Check(Thread)).to.equal(false)
            expect(Base:HasStatus("normal"):Check(Thread)).to.equal(false)
            expect(Base:HasStatus("dead"):Check(Thread)).to.equal(true)

            expect(Base:HasStatus(function() return "suspended" end):Check(Thread)).to.equal(false)
            expect(Base:HasStatus(function() return "running" end):Check(Thread)).to.equal(false)
            expect(Base:HasStatus(function() return "normal" end):Check(Thread)).to.equal(false)
            expect(Base:HasStatus(function() return "dead" end):Check(Thread)).to.equal(true)
        end)

        it("should accept threads given 'normal'", function()
            local DidRun = false
            local TestCoroutine = coroutine.create(function(Callback)
                Callback()
            end)

            task.spawn(function()
                local Thread = coroutine.running()

                task.spawn(TestCoroutine, function()
                    expect(Base:HasStatus("suspended"):Check(Thread)).to.equal(false)
                    expect(Base:HasStatus("running"):Check(Thread)).to.equal(false)
                    expect(Base:HasStatus("normal"):Check(Thread)).to.equal(true)
                    expect(Base:HasStatus("dead"):Check(Thread)).to.equal(false)

                    expect(Base:HasStatus(function() return "suspended" end):Check(Thread)).to.equal(false)
                    expect(Base:HasStatus(function() return "running" end):Check(Thread)).to.equal(false)
                    expect(Base:HasStatus(function() return "normal" end):Check(Thread)).to.equal(true)
                    expect(Base:HasStatus(function() return "dead" end):Check(Thread)).to.equal(false)
                    DidRun = true
                end)
            end)

            expect(DidRun).to.equal(true)
        end)
    end)
end