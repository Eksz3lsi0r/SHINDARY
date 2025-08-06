-- Game Coordinator - Integration zwischen allen Systemen
--!strict

local Players = game:GetService("Players")
local _RunService = game:GetService("RunService")

-- Import our new game systems
local _ServerStorage = game:GetService("ServerStorage")
-- Note: These requires work at runtime but LSP may show errors
local DynamicWorldGenerator = require(script.Parent:FindFirstChild("DynamicWorldGenerator") :: ModuleScript)
local GameLoopManager = require(script.Parent:FindFirstChild("GameLoopManager") :: ModuleScript)

local GameCoordinator = {}
GameCoordinator.__index = GameCoordinator

function GameCoordinator.new()
    local self = setmetatable({}, GameCoordinator)

    -- Initialize components
    self.gameLoopManager = GameLoopManager.new()
    self.worldGenerator = DynamicWorldGenerator.new()

    self.isInitialized = false
    self.activeSession = nil

    return self
end

-- Initialize the complete game system
function GameCoordinator:initialize()
    if self.isInitialized then
        warn("🎮 GameCoordinator already initialized")
        return
    end

    print("🎮 Initializing Subway Surfers Game Coordinator...")

    -- Setup player management
    self:setupPlayerManagement()

    -- Wait for first player to start the system
    if #Players:GetPlayers() > 0 then
        -- Players already in game
        for _, player in ipairs(Players:GetPlayers()) do
            self:handlePlayerJoined(player)
        end
    else
        -- Wait for first player
        Players.PlayerAdded:Connect(function(player)
            self:handlePlayerJoined(player)
        end)
    end

    self.isInitialized = true
    print("✅ Game Coordinator initialized successfully")
end

-- Setup player connection management
function GameCoordinator:setupPlayerManagement()
    Players.PlayerAdded:Connect(function(player)
        self:handlePlayerJoined(player)
    end)

    Players.PlayerRemoving:Connect(function(player)
        self:handlePlayerLeaving(player)
    end)
end

-- Handle player joining
function GameCoordinator:handlePlayerJoined(player: Player)
    print(`👤 Player {player.Name} joined - setting up game environment`)

    -- Initialize player in game systems
    task.spawn(function()
        -- Wait for character
        local character = player.Character or player.CharacterAdded:Wait()
        local _humanoid = character:WaitForChild("Humanoid")
        local rootPart = character:WaitForChild("HumanoidRootPart") :: BasePart

        -- Position player at start
        rootPart.Position = Vector3.new(0, 5, 0)

        -- Auto-start game for immediate play
        self:startGameSession(player)
    end)
end

-- Handle player leaving
function GameCoordinator:handlePlayerLeaving(player: Player)
    print(`👤 Player {player.Name} leaving`)

    -- Cleanup handled by GameLoopManager
end

-- Start a new game session
function GameCoordinator:startGameSession(initiatingPlayer: Player)
    print(`🚀 Starting game session for {initiatingPlayer.Name}`)

    -- Start world generation
    local playerPosition = Vector3.new(0, 5, 0)
    if initiatingPlayer.Character and initiatingPlayer.Character:FindFirstChild("HumanoidRootPart") then
        local rootPart = initiatingPlayer.Character:FindFirstChild("HumanoidRootPart") :: BasePart
        playerPosition = rootPart.Position
    end

    self.worldGenerator:start(playerPosition)

    -- Start game loop
    self.gameLoopManager:startGame(initiatingPlayer)

    -- Set up integration between systems
    self:integrateGameSystems()

    self.activeSession = {
        startTime = tick(),
        initiatingPlayer = initiatingPlayer,
    }

    print("✅ Game session started successfully")
end

-- Integrate game systems to work together
function GameCoordinator:integrateGameSystems()
    -- Create connection between PlayerController and WorldGenerator
    -- This will be called from PlayerController when position updates

    -- Store reference for global access
    _G.GameCoordinator = self
    _G.WorldGenerator = self.worldGenerator
    _G.GameLoop = self.gameLoopManager

    print("🔗 Game systems integrated")
end

-- Update world based on player position (called from PlayerController)
function GameCoordinator:updateWorldForPlayer(player: Player, position: Vector3)
    if self.worldGenerator and self.worldGenerator.state and self.worldGenerator.state.isActive then
        self.worldGenerator:updatePlayerPosition(position)
    end
end

-- Get world objects near position (for collision detection)
function GameCoordinator:getWorldObjectsNear(position: Vector3, radius: number)
    if self.worldGenerator then
        return self.worldGenerator:getObjectsNear(position, radius)
    end
    return {}
end

-- Handle object collection (coins, power-ups)
function GameCoordinator:handleObjectCollection(player: Player, objectType: string, value: any)
    if objectType == "COIN" then
        self.gameLoopManager:handleCoinCollected(player, value or 10)
    elseif objectType == "POWERUP" then
        self.gameLoopManager:handlePowerUpCollected(player, value)
    end
end

-- Handle player collision with obstacle
function GameCoordinator:handlePlayerCollision(player: Player, obstacleType: string)
    self.gameLoopManager:handlePlayerCollision(player, obstacleType)
end

-- Stop current game session
function GameCoordinator:stopGameSession(reason: string)
    print(`🛑 Stopping game session: {reason}`)

    if self.worldGenerator then
        self.worldGenerator:stop()
    end

    if self.gameLoopManager then
        self.gameLoopManager:endGame(reason)
    end

    self.activeSession = nil
end

-- Restart game session
function GameCoordinator:restartGameSession(player: Player)
    print(`🔄 Restarting game session for {player.Name}`)

    self:stopGameSession("Manual restart")

    task.wait(1) -- Brief pause for cleanup

    self:startGameSession(player)
end

-- Get system status
function GameCoordinator:getStatus()
    return {
        initialized = self.isInitialized,
        activeSession = self.activeSession ~= nil,
        worldGeneratorActive = self.worldGenerator and self.worldGenerator.state and self.worldGenerator.state.isActive
            or false,
        gameLoopState = self.gameLoopManager and self.gameLoopManager:getGameState() or "UNKNOWN",
        playerCount = #Players:GetPlayers(),
    }
end

-- Cleanup systems
function GameCoordinator:cleanup()
    print("🧹 Cleaning up Game Coordinator")

    if self.worldGenerator then
        self.worldGenerator:stop()
    end

    if self.gameLoopManager then
        self.gameLoopManager:cleanup()
    end

    -- Clear global references
    _G.GameCoordinator = nil
    _G.WorldGenerator = nil
    _G.GameLoop = nil

    self.isInitialized = false
    print("✅ Game Coordinator cleanup complete")
end

return GameCoordinator
