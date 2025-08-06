-- Game Coordinator - Integration zwischen allen Systemen
--!strict

local Players = game:GetService("Players")
local _RunService = game:GetService("RunService")
local _ServerStorage = game:GetService("ServerStorage")

-- Demand-Loading für Module um circular dependencies zu vermeiden
local DynamicWorldGenerator: any = nil
local GameLoopManager: any = nil

-- Lazy Loading Funktion
local function getDynamicWorldGenerator(): any?
    if not DynamicWorldGenerator then
        local success, module = pcall(function()
            local moduleScript = script.Parent:FindFirstChild("DynamicWorldGenerator")
            return if moduleScript then require(moduleScript) else nil
        end)
        if success and module then
            DynamicWorldGenerator = module
        else
            warn("[GameCoordinator] DynamicWorldGenerator konnte nicht geladen werden")
        end
    end
    return DynamicWorldGenerator
end

local function getGameLoopManager(): any?
    if not GameLoopManager then
        local success, module = pcall(function()
            local moduleScript = script.Parent:FindFirstChild("GameLoopManager")
            return if moduleScript then require(moduleScript) else nil
        end)
        if success and module then
            GameLoopManager = module
        else
            warn("[GameCoordinator] GameLoopManager konnte nicht geladen werden")
        end
    end
    return GameLoopManager
end

-- Type Definitions für bessere Type-Safety
export type GameSession = {
    startTime: number,
    initiatingPlayer: Player,
}

export type GameCoordinatorStatus = {
    initialized: boolean,
    activeSession: boolean,
    worldGeneratorActive: boolean,
    gameLoopState: string,
    playerCount: number,
}

local GameCoordinator = {}
GameCoordinator.__index = GameCoordinator

export type GameCoordinator = typeof(setmetatable(
    {} :: {
        gameLoopManager: any,
        worldGenerator: any,
        isInitialized: boolean,
        activeSession: GameSession?,
    },
    GameCoordinator
))

function GameCoordinator.new(): GameCoordinator
    local self = setmetatable({}, GameCoordinator) :: GameCoordinator

    -- Prüfe ob Module verfügbar sind (lazy loading)
    local worldGen = getDynamicWorldGenerator()
    local gameLoop = getGameLoopManager()

    if not worldGen or not gameLoop then
        warn("🔧 GameCoordinator: Einige Module konnten nicht geladen werden, verwende Fallback")
        self.gameLoopManager = nil
        self.worldGenerator = nil
    else
        -- Initialize components
        self.gameLoopManager = gameLoop.new()
        self.worldGenerator = worldGen.new()
    end

    self.isInitialized = false
    self.activeSession = nil

    return self
end -- Initialize the complete game system
function GameCoordinator:initialize(): boolean
    if self.isInitialized then
        warn("🎮 GameCoordinator already initialized")
        return true
    end

    print("🎮 Initializing Subway Surfers Game Coordinator...")

    -- Prüfe kritische Abhängigkeiten
    if not self.gameLoopManager or not self.worldGenerator then
        warn("❌ GameCoordinator: Kritische Komponenten fehlen")
        return false
    end

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
    return true
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

    if self.worldGenerator and self.worldGenerator.start then
        self.worldGenerator:start(playerPosition)
    end

    -- Start game loop
    if self.gameLoopManager and self.gameLoopManager.startGame then
        self.gameLoopManager:startGame(initiatingPlayer)
    end

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
        if self.worldGenerator.updatePlayerPosition then
            self.worldGenerator:updatePlayerPosition(position)
        end
    end
end

-- Get world objects near position (for collision detection)
function GameCoordinator:getWorldObjectsNear(position: Vector3, radius: number): { any }
    if self.worldGenerator and self.worldGenerator.getObjectsNear then
        return self.worldGenerator:getObjectsNear(position, radius)
    end
    return {}
end

-- Handle object collection (coins, power-ups)
function GameCoordinator:handleObjectCollection(player: Player, objectType: string, value: any)
    if not self.gameLoopManager then
        return
    end

    if objectType == "COIN" then
        if self.gameLoopManager.handleCoinCollected then
            self.gameLoopManager:handleCoinCollected(player, value or 10)
        end
    elseif objectType == "POWERUP" then
        if self.gameLoopManager.handlePowerUpCollected then
            self.gameLoopManager:handlePowerUpCollected(player, value)
        end
    end
end

-- Handle player collision with obstacle
function GameCoordinator:handlePlayerCollision(player: Player, obstacleType: string)
    if self.gameLoopManager and self.gameLoopManager.handlePlayerCollision then
        self.gameLoopManager:handlePlayerCollision(player, obstacleType)
    end
end

-- Stop current game session
function GameCoordinator:stopGameSession(reason: string)
    print(`🛑 Stopping game session: {reason}`)

    if self.worldGenerator and self.worldGenerator.stop then
        self.worldGenerator:stop()
    end

    if self.gameLoopManager and self.gameLoopManager.endGame then
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
function GameCoordinator:getStatus(): GameCoordinatorStatus
    return {
        initialized = self.isInitialized,
        activeSession = self.activeSession ~= nil,
        worldGeneratorActive = self.worldGenerator and self.worldGenerator.state and self.worldGenerator.state.isActive
            or false,
        gameLoopState = self.gameLoopManager
                and self.gameLoopManager.getGameState
                and self.gameLoopManager:getGameState()
            or "UNKNOWN",
        playerCount = #Players:GetPlayers(),
    }
end

-- Cleanup systems
function GameCoordinator:cleanup()
    print("🧹 Cleaning up Game Coordinator")

    if self.worldGenerator and self.worldGenerator.stop then
        self.worldGenerator:stop()
    end

    if self.gameLoopManager and self.gameLoopManager.cleanup then
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
