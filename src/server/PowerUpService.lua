--!strict
-- PowerUpService.lua - Server-side power-up management for Subway Surfers
local PowerUpService = {}

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

-- Import shared modules with error handling
local GameConfig
local SubwaySurfersGameplay

local success, error = pcall(function()
    GameConfig = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("GameConfig"))
end)

if not success then
    warn("[PowerUpService] GameConfig not found, using fallback:", error)
    GameConfig = {
        PowerUps = {
            JETPACK = { name = "Jetpack", duration = 8, effect = "flight", color = Color3.fromRGB(255, 140, 0) },
            SUPER_SNEAKERS = {
                name = "Super Sneakers",
                duration = 10,
                effect = "highjump",
                color = Color3.fromRGB(0, 255, 0),
            },
            COIN_MAGNET = {
                name = "Coin Magnet",
                duration = 15,
                effect = "magnet",
                color = Color3.fromRGB(255, 0, 255),
            },
            MULTIPLIER = {
                name = "2x Multiplier",
                duration = 20,
                effect = "doublescore",
                color = Color3.fromRGB(255, 255, 0),
            },
        },
    }
end

local success2, error2 = pcall(function()
    SubwaySurfersGameplay = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("SubwaySurfersGameplay"))
end)

if not success2 then
    warn("[PowerUpService] SubwaySurfersGameplay not found, using fallback:", error2)
    SubwaySurfersGameplay = {
        PowerUps = {
            JETPACK = { name = "Jetpack", duration = 8, effect = "flight", color = Color3.fromRGB(255, 140, 0) },
            SUPER_SNEAKERS = {
                name = "Super Sneakers",
                duration = 10,
                effect = "highjump",
                color = Color3.fromRGB(0, 255, 0),
            },
            COIN_MAGNET = {
                name = "Coin Magnet",
                duration = 15,
                effect = "magnet",
                color = Color3.fromRGB(255, 0, 255),
            },
            MULTIPLIER = {
                name = "2x Multiplier",
                duration = 20,
                effect = "doublescore",
                color = Color3.fromRGB(255, 255, 0),
            },
        },
    }
end

-- Types
export type PowerUpInstance = {
    player: Player,
    powerUpType: string,
    startTime: number,
    duration: number,
    active: boolean,
}

-- Local storage
local activePowerUps: { [Player]: { [string]: PowerUpInstance } } = {}
local powerUpEffects = {}
local cleanupConnections = {}

-- Remote Events
local PowerUpActivatedEvent: RemoteEvent
local PowerUpDeactivatedEvent: RemoteEvent

-- Initialize PowerUpService
function PowerUpService:Initialize()
    print("[PowerUpService] Initializing power-up system...")

    -- Wait for ReplicatedStorage to be ready
    if not ReplicatedStorage:FindFirstChild("RemoteEvents") then
        warn("[PowerUpService] RemoteEvents folder not found, creating it...")
        local remoteEventsFolder = Instance.new("Folder")
        remoteEventsFolder.Name = "RemoteEvents"
        remoteEventsFolder.Parent = ReplicatedStorage
    end

    local RemoteEvents = ReplicatedStorage:WaitForChild("RemoteEvents")

    -- Wait for all required remote events
    PowerUpActivatedEvent = RemoteEvents:WaitForChild("PowerUpActivated")
    PowerUpDeactivatedEvent = RemoteEvents:WaitForChild("PowerUpDeactivated")

    print("[PowerUpService] Remote events connected successfully")

    -- Initialize power-up effects
    local success, errorMsg = pcall(function()
        self:SetupPowerUpEffects()
    end)

    if not success then
        warn("[PowerUpService] Failed to setup power-up effects:", errorMsg)
    end

    -- Connect to update loop
    RunService.Heartbeat:Connect(function(deltaTime)
        self:UpdateActivePowerUps(deltaTime)
    end)

    -- Handle player cleanup
    Players.PlayerRemoving:Connect(function(player)
        self:CleanupPlayerPowerUps(player)
    end)

    print("[PowerUpService] ✅ PowerUpService initialized successfully")
end

-- Setup power-up effects
function PowerUpService:SetupPowerUpEffects()
    -- Create default power-up data
    local powerUpDefaults = {
        JETPACK = {
            name = "Jetpack",
            duration = 8,
            effect = "flight",
            color = Color3.fromRGB(255, 140, 0),
        },
        SUPER_SNEAKERS = {
            name = "Super Sneakers",
            duration = 10,
            effect = "highjump",
            color = Color3.fromRGB(0, 255, 0),
        },
        COIN_MAGNET = {
            name = "Coin Magnet",
            duration = 15,
            effect = "magnet",
            color = Color3.fromRGB(255, 0, 255),
        },
        MULTIPLIER = {
            name = "2x Multiplier",
            duration = 20,
            effect = "doublescore",
            color = Color3.fromRGB(255, 255, 0),
        },
    }

    -- Use power-ups from GameConfig if available, otherwise use defaults
    if GameConfig and GameConfig.PowerUps then
        powerUpEffects = {}
        for powerUpType, defaultData in pairs(powerUpDefaults) do
            if GameConfig.PowerUps[powerUpType] then
                powerUpEffects[powerUpType] = GameConfig.PowerUps[powerUpType]
                print("[PowerUpService] Using GameConfig power-up:", powerUpType)
            else
                warn("[PowerUpService] GameConfig missing", powerUpType, "- using default")
                powerUpEffects[powerUpType] = defaultData
            end
        end
    else
        warn("[PowerUpService] GameConfig.PowerUps not available - using all defaults")
        powerUpEffects = powerUpDefaults
    end

    -- Also check SubwaySurfersGameplay as backup
    if SubwaySurfersGameplay and SubwaySurfersGameplay.PowerUps then
        for powerUpType, defaultData in pairs(powerUpDefaults) do
            if not powerUpEffects[powerUpType] and SubwaySurfersGameplay.PowerUps[powerUpType] then
                powerUpEffects[powerUpType] = SubwaySurfersGameplay.PowerUps[powerUpType]
                print("[PowerUpService] Using SubwaySurfersGameplay power-up:", powerUpType)
            end
        end
    end

    print("[PowerUpService] Power-up effects setup complete")

    -- Verify that we have the required power-ups
    local requiredPowerUps = { "JETPACK", "SUPER_SNEAKERS", "COIN_MAGNET", "MULTIPLIER" }
    for _, powerUpType in ipairs(requiredPowerUps) do
        if not powerUpEffects[powerUpType] then
            warn("[PowerUpService] Missing power-up:", powerUpType)
        else
            print("[PowerUpService] ✅", powerUpType, "configured successfully")
        end
    end
end

-- Activate power-up for a specific player
function PowerUpService:ActivatePowerUp(player: Player, powerUpType: string): boolean
    if not player or not player.Parent then
        warn("[PowerUpService] Invalid player for power-up activation")
        return false
    end

    local powerUpEffect = powerUpEffects[powerUpType]
    if not powerUpEffect then
        warn("[PowerUpService] Unknown power-up type:", powerUpType)
        return false
    end

    -- Check if already active
    if activePowerUps[player] and activePowerUps[player][powerUpType] then
        warn("[PowerUpService] Power-up", powerUpType, "already active for", player.Name)
        return false
    end

    -- Initialize player's power-up table if needed
    if not activePowerUps[player] then
        activePowerUps[player] = {}
    end

    -- Create power-up instance
    local powerUpInstance: PowerUpInstance = {
        player = player,
        powerUpType = powerUpType,
        startTime = tick(),
        duration = powerUpEffect.duration or 10,
        active = true,
    }

    activePowerUps[player][powerUpType] = powerUpInstance

    -- Apply power-up effect
    self:ApplyPowerUpEffect(player, powerUpType)

    -- Notify client
    if PowerUpActivatedEvent then
        PowerUpActivatedEvent:FireClient(player, powerUpType, powerUpInstance.duration)
    end

    print("[PowerUpService] Activated", powerUpType, "for", player.Name, "duration:", powerUpInstance.duration)
    return true
end

-- Apply power-up effect
function PowerUpService:ApplyPowerUpEffect(player: Player, powerUpType: string)
    local character = player.Character
    if not character then
        return
    end

    if powerUpType == "JETPACK" then
        self:ApplyJetpackEffect(player)
    elseif powerUpType == "SUPER_SNEAKERS" then
        self:ApplySuperSneakersEffect(player)
    elseif powerUpType == "COIN_MAGNET" then
        self:ApplyCoinMagnetEffect(player)
    elseif powerUpType == "MULTIPLIER" then
        self:ApplyMultiplierEffect(player)
    end
end

-- Apply Jetpack effect
function PowerUpService:ApplyJetpackEffect(player: Player)
    local character = player.Character
    if not character then
        return
    end

    local rootPart = character:FindFirstChild("HumanoidRootPart")
    if not rootPart then
        return
    end

    -- Add flight capability
    local bodyVelocity = Instance.new("BodyVelocity")
    bodyVelocity.MaxForce = Vector3.new(0, math.huge, 0)
    bodyVelocity.Velocity = Vector3.new(0, 25, 0)
    bodyVelocity.Name = "JetpackForce"
    bodyVelocity.Parent = rootPart

    print("[PowerUpService] Jetpack effect applied to", player.Name)
end

-- Apply Super Sneakers effect
function PowerUpService:ApplySuperSneakersEffect(player: Player)
    local character = player.Character
    if not character then
        return
    end

    local humanoid = character:FindFirstChild("Humanoid")
    if not humanoid then
        return
    end

    -- Store original values and enhance jump
    humanoid:SetAttribute("OriginalJumpPower", humanoid.JumpPower)
    humanoid.JumpPower = (humanoid.JumpPower or 50) * 2

    print("[PowerUpService] Super Sneakers effect applied to", player.Name)
end

-- Apply Coin Magnet effect
function PowerUpService:ApplyCoinMagnetEffect(player: Player)
    -- Coin magnet effect will be handled in the update loop
    print("[PowerUpService] Coin Magnet effect applied to", player.Name)
end

-- Apply Multiplier effect
function PowerUpService:ApplyMultiplierEffect(player: Player)
    -- Multiplier effect will be handled by score service
    print("[PowerUpService] Score Multiplier effect applied to", player.Name)
end

-- Deactivate power-up
function PowerUpService:DeactivatePowerUp(player: Player, powerUpType: string)
    if not activePowerUps[player] or not activePowerUps[player][powerUpType] then
        return
    end

    -- Remove power-up effect
    self:RemovePowerUpEffect(player, powerUpType)

    -- Remove from active list
    activePowerUps[player][powerUpType] = nil

    -- Notify client
    if PowerUpDeactivatedEvent then
        PowerUpDeactivatedEvent:FireClient(player, powerUpType)
    end

    print("[PowerUpService] Deactivated", powerUpType, "for", player.Name)
end

-- Remove power-up effect
function PowerUpService:RemovePowerUpEffect(player: Player, powerUpType: string)
    local character = player.Character
    if not character then
        return
    end

    if powerUpType == "JETPACK" then
        self:RemoveJetpackEffect(player)
    elseif powerUpType == "SUPER_SNEAKERS" then
        self:RemoveSuperSneakersEffect(player)
    elseif powerUpType == "COIN_MAGNET" then
        self:RemoveCoinMagnetEffect(player)
    elseif powerUpType == "MULTIPLIER" then
        self:RemoveMultiplierEffect(player)
    end
end

-- Remove Jetpack effect
function PowerUpService:RemoveJetpackEffect(player: Player)
    local character = player.Character
    if not character then
        return
    end

    local rootPart = character:FindFirstChild("HumanoidRootPart")
    if not rootPart then
        return
    end

    local jetpackForce = rootPart:FindFirstChild("JetpackForce")
    if jetpackForce then
        jetpackForce:Destroy()
    end
end

-- Remove Super Sneakers effect
function PowerUpService:RemoveSuperSneakersEffect(player: Player)
    local character = player.Character
    if not character then
        return
    end

    local humanoid = character:FindFirstChild("Humanoid")
    if not humanoid then
        return
    end

    -- Restore original jump power
    local originalJumpPower = humanoid:GetAttribute("OriginalJumpPower")
    if originalJumpPower then
        humanoid.JumpPower = originalJumpPower
        humanoid:SetAttribute("OriginalJumpPower", nil)
    end
end

-- Remove Coin Magnet effect
function PowerUpService:RemoveCoinMagnetEffect(player: Player)
    -- Nothing to remove for coin magnet
end

-- Remove Multiplier effect
function PowerUpService:RemoveMultiplierEffect(player: Player)
    -- Nothing to remove for multiplier
end

-- Update active power-ups
function PowerUpService:UpdateActivePowerUps(deltaTime: number)
    for player, playerPowerUps in pairs(activePowerUps) do
        for powerUpType, powerUpInstance in pairs(playerPowerUps) do
            if powerUpInstance.active then
                local elapsed = tick() - powerUpInstance.startTime
                if elapsed >= powerUpInstance.duration then
                    self:DeactivatePowerUp(player, powerUpType)
                end
            end
        end
    end
end

-- Check if player has power-up active
function PowerUpService:HasPowerUpActive(player: Player, powerUpType: string): boolean
    return activePowerUps[player] and activePowerUps[player][powerUpType] and activePowerUps[player][powerUpType].active
        or false
end

-- Get active power-ups for player
function PowerUpService:GetActivePowerUps(player: Player): { string }
    if not activePowerUps[player] then
        return {}
    end

    local active = {}
    for powerUpType, powerUpInstance in pairs(activePowerUps[player]) do
        if powerUpInstance.active then
            table.insert(active, powerUpType)
        end
    end
    return active
end

-- Clean up player power-ups
function PowerUpService:CleanupPlayerPowerUps(player: Player)
    if activePowerUps[player] then
        for powerUpType, _ in pairs(activePowerUps[player]) do
            self:DeactivatePowerUp(player, powerUpType)
        end
        activePowerUps[player] = nil
    end

    if cleanupConnections[player] then
        for _, connection in pairs(cleanupConnections[player]) do
            connection:Disconnect()
        end
        cleanupConnections[player] = nil
    end
end

-- Start tracking player
function PowerUpService:StartTrackingPlayer(player: Player)
    print("[PowerUpService] Started tracking power-ups for:", player.Name)
    activePowerUps[player] = {}
end

-- Stop tracking player
function PowerUpService:StopTrackingPlayer(player: Player)
    self:CleanupPlayerPowerUps(player)
    print("[PowerUpService] Stopped tracking power-ups for:", player.Name)
end

return PowerUpService
