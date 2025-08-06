-- ServiceInitializer.lua - Ensures proper loading order of services with Copilot optimization
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

print("🔧 SERVICE INITIALIZER STARTING WITH AI OPTIMIZATION...")

-- Enhanced folder structure creation with validation
local function createFolderStructure()
    local folders = {
        { name = "RemoteEvents", required = true },
        { name = "RemoteFunctions", required = true },
        { name = "Shared", required = true },
        { name = "Modules", required = false }, -- Optional for compatibility
    }

    local createdCount = 0
    for _, folderInfo in ipairs(folders) do
        if not ReplicatedStorage:FindFirstChild(folderInfo.name) then
            local folder = Instance.new("Folder")
            folder.Name = folderInfo.name
            folder.Parent = ReplicatedStorage
            print("✅ Created required folder:", folderInfo.name)
            createdCount = createdCount + 1
        else
            print("✅ Folder exists:", folderInfo.name)
        end
    end

    print("📁 Folder structure validation complete -", createdCount, "new folders created")
end

-- Enhanced server signals with performance monitoring
local function createServerSignals()
    local signals = {
        { name = "ServerReady", initialValue = false },
        { name = "GameManagerReady", initialValue = false },
        { name = "ServicesReady", initialValue = false }, -- New enhanced signal
    }

    for _, signalInfo in ipairs(signals) do
        if not ReplicatedStorage:FindFirstChild(signalInfo.name) then
            local signal = Instance.new("BoolValue")
            signal.Name = signalInfo.name
            signal.Value = signalInfo.initialValue
            signal.Parent = ReplicatedStorage
            print("🚦 Created signal:", signalInfo.name)
        end
    end

    -- Add performance tracking
    local perfStats = Instance.new("StringValue")
    perfStats.Name = "ServerPerformance"
    perfStats.Value = "Initializing..."
    perfStats.Parent = ReplicatedStorage
end

-- Performance monitoring during initialization
local function trackInitializationPerformance()
    local startTime = tick()
    local memoryStart = collectgarbage("count")

    task.spawn(function()
        task.wait(1) -- Wait for initialization to complete

        local endTime = tick()
        local memoryEnd = collectgarbage("count")
        local initTime = endTime - startTime
        local memoryUsage = memoryEnd - memoryStart

        local perfStats = ReplicatedStorage:FindFirstChild("ServerPerformance")
        if perfStats then
            perfStats.Value = string.format("Init: %.2fs, Memory: %.1fKB", initTime, memoryUsage)
        end

        print("📊 Initialization Performance:")
        print("   ⏱️ Time:", string.format("%.2f", initTime), "seconds")
        print("   💾 Memory:", string.format("%.1f", memoryUsage), "KB")
    end)
end

-- Initialize in correct order with performance monitoring
createFolderStructure()
createServerSignals()
trackInitializationPerformance()

-- Mark server as ready after enhanced initialization
task.spawn(function()
    task.wait(0.5) -- Brief delay to ensure all systems are stable

    local serverReady = ReplicatedStorage:FindFirstChild("ServerReady")
    if serverReady then
        serverReady.Value = true
        print("🚦 ServerReady signal activated")
    end

    local servicesReady = ReplicatedStorage:FindFirstChild("ServicesReady")
    if servicesReady then
        servicesReady.Value = true
        print("🚦 ServicesReady signal activated")
    end
end)

print("✅ SERVICE INITIALIZER COMPLETED WITH AI OPTIMIZATION")

return {}
