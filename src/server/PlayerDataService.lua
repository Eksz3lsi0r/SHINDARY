-- PlayerDataService.lua - Handle player data loading and saving
local DataStoreService = game:GetService("DataStoreService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local SharedFolder = ReplicatedStorage:WaitForChild("Shared")
local GameState = require(SharedFolder:WaitForChild("GameState"))

local PlayerDataService = {}

-- Data store for player data
local PlayerDataStore = DataStoreService:GetDataStore("PlayerData_v1")

-- Cache for loaded player data
local PlayerCache = {}

-- Load player data from DataStore
function PlayerDataService:LoadPlayerData(player)
    if PlayerCache[player.UserId] then
        return PlayerCache[player.UserId]
    end

    local success, playerData = pcall(function()
        return PlayerDataStore:GetAsync(player.UserId)
    end)

    if success and playerData then
        -- Validate and merge with defaults
        local data = {}
        for key, defaultValue in pairs(GameState.DefaultPlayerData) do
            data[key] = playerData[key] or defaultValue
        end

        PlayerCache[player.UserId] = data
        print("[PlayerDataService] Loaded data for:", player.Name)
        return data
    else
        -- Return default data for new players
        local defaultData = {}
        for key, value in pairs(GameState.DefaultPlayerData) do
            defaultData[key] = value
        end

        PlayerCache[player.UserId] = defaultData
        print("[PlayerDataService] Created new data for:", player.Name)
        return defaultData
    end
end

-- Save player data to DataStore
function PlayerDataService:SavePlayerData(player, playerData)
    if not playerData then
        return
    end

    local success, error = pcall(function()
        PlayerDataStore:SetAsync(player.UserId, playerData)
    end)

    if success then
        PlayerCache[player.UserId] = playerData
        print("[PlayerDataService] Saved data for:", player.Name)
    else
        warn("[PlayerDataService] Failed to save data for:", player.Name, error)
    end
end

-- Get cached player data
function PlayerDataService:GetCachedData(player)
    return PlayerCache[player.UserId]
end

-- Update specific player data field
function PlayerDataService:UpdatePlayerField(player, field, value)
    local playerData = PlayerCache[player.UserId]
    if playerData and playerData[field] ~= nil then
        playerData[field] = value
        return true
    end
    return false
end

-- Clean up cache when player leaves
function PlayerDataService:CleanupPlayerCache(player)
    PlayerCache[player.UserId] = nil
end

return PlayerDataService
