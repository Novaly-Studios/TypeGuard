--!optimize 2
--!native

--[[ local Buffer = buffer.create(1000000)

for Index = 0, buffer.len(Buffer) - 1 do
    buffer.writei8(Buffer, Index, (math.random(0, 7) == 0 and math.random(0, 255) or 100))
end

local Count = 25

local Config = {}
local Test = game and require(game.ReplicatedFirst.TypeGuard.Core.CompressibleCache.Sequencer)(Config) or require("./Sequencer")(Config)
local DecompressTimes = {}
local CompressTimes = {}

local function Median(Target)
    table.sort(Target)
    return Target[math.ceil(#Target / 2)]
end

for Round = 1, Count do
    local Start = os.clock()
    local Compressed = Test.Compress(Buffer)
    table.insert(CompressTimes, os.clock() - Start)

    if (task) then task.wait() end

    Start = os.clock()
    Test.Decompress(Compressed)
    table.insert(DecompressTimes, os.clock() - Start)

    if (task) then task.wait() end
    print(`Round {Round} convergence - compression: {("%.4f"):format(Median(CompressTimes))}, decompression: {("%.4f"):format(Median(DecompressTimes))}`)
end

print("Compression:", Median(CompressTimes))
print("\tProjected Bytes/s:", buffer.len(Buffer) / Median(CompressTimes))
print("Decompression:", Median(DecompressTimes))
print("\tProjected Bytes/s:", buffer.len(Buffer) / Median(DecompressTimes))

local Compressed = Test.Compress(Buffer)
local Decompressed = Test.Decompress(Compressed)
print("Correct:", buffer.tostring(Decompressed) == buffer.tostring(Buffer))
print("Ratio:", buffer.len(Buffer) / buffer.len(Compressed)) ]]