--!strict
-- RemoteEventsService.lua - Manages remote events and functions for client-server communication
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local RemoteEventsService = {}

-- Create remote events and functions
function RemoteEventsService:Initialize()
    print("[RemoteEventsService] Initializing remote events...")

    -- Ensure RemoteEvents folder exists
    if not ReplicatedStorage:FindFirstChild("RemoteEvents") then
        local folder = Instance.new("Folder")
        folder.Name = "RemoteEvents"
        folder.Parent = ReplicatedStorage
    end

    -- Ensure RemoteFunctions folder exists
    if not ReplicatedStorage:FindFirstChild("RemoteFunctions") then
        local folder = Instance.new("Folder")
        folder.Name = "RemoteFunctions"
        folder.Parent = ReplicatedStorage
    end

    -- Ensure Modules folder exists
    if not ReplicatedStorage:FindFirstChild("Shared") then
        local folder = Instance.new("Folder")
        folder.Name = "Shared"
        folder.Parent = ReplicatedStorage
    end

    local remoteEventsFolder = ReplicatedStorage:WaitForChild("RemoteEvents")
    local remoteFunctionsFolder = ReplicatedStorage:WaitForChild("RemoteFunctions")

    -- Additional Remote Events (beyond what's in default.project.json)
    local additionalEvents = {
        "PowerUpActivated",
        "PowerUpDeactivated",
        "ObstacleSpawned",
        "CollectibleSpawned",
        "SegmentSpawned",
        "UIUpdate",
    }

    for _, eventName in ipairs(additionalEvents) do
        if not remoteEventsFolder:FindFirstChild(eventName) then
            local remoteEvent = Instance.new("RemoteEvent")
            remoteEvent.Name = eventName
            remoteEvent.Parent = remoteEventsFolder
        end
    end

    -- Additional Remote Functions
    local additionalFunctions = {
        "GetLeaderboard",
        "PurchaseItem",
    }

    for _, functionName in ipairs(additionalFunctions) do
        if not remoteFunctionsFolder:FindFirstChild(functionName) then
            local remoteFunction = Instance.new("RemoteFunction")
            remoteFunction.Name = functionName
            remoteFunction.Parent = remoteFunctionsFolder
        end
    end

    print("[RemoteEventsService] Remote events initialized successfully")
end

return RemoteEventsService
