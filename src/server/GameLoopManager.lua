-- Game Loop Manager für Subway Surfers Style Game
--!strict

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local _TweenService = game:GetService("TweenService") -- Prefix with _ to silence warning

local GameLoopManager = {}
GameLoopManager.__index = GameLoopManager

-- Game States
local GameState = {
    MENU = "MENU",
    STARTING = "STARTING",
    PLAYING = "PLAYING",
    PAUSED = "PAUSED",
    GAME_OVER = "GAME_OVER",
    RESTARTING = "RESTARTING",
}

-- Type Definitions für bessere Type Safety
export type RemoteEventsType = {
    GameStart: RemoteEvent?,
    GameEnd: RemoteEvent?,
    GameRestart: RemoteEvent?,
    PlayerCollision: RemoteEvent?,
    CoinCollected: RemoteEvent?,
    PowerUpCollected: RemoteEvent?,
    ScoreUpdate: RemoteEvent?,
}

export type SessionDataType = {
    sessionId: string,
    state: string,
    startTime: number,
    endTime: number?,
    players: { PlayerGameData },
    worldGenerator: any?,
    currentSpeed: number,
    difficulty: number,
}

-- Type Definitions
type PlayerGameData = {
    player: Player,
    score: number,
    isAlive: boolean,
    startTime: number,
    endTime: number?,
    distance: number,
    coinsCollected: number,
    powerUpsUsed: number,
}

type GameSession = {
    sessionId: string,
    state: string,
    startTime: number,
    endTime: number?,
    players: { PlayerGameData },
    worldGenerator: any?,
    currentSpeed: number,
    difficulty: number,
}

function GameLoopManager.new()
    local self = setmetatable({}, GameLoopManager)

    self.currentSession = nil :: SessionDataType?
    self.gameState = GameState.MENU
    self.updateConnection = nil :: RBXScriptConnection?
    self.remoteEvents = {} :: RemoteEventsType

    self:setupRemoteEvents()
    self:setupPlayerConnections()

    return self
end

-- Setup Remote Events
function GameLoopManager:setupRemoteEvents()
    -- Setup folders if they don't exist
    local remoteEventsFolder = ReplicatedStorage:FindFirstChild("RemoteEvents")
    if not remoteEventsFolder then
        local newFolder = Instance.new("Folder")
        newFolder.Name = "RemoteEvents"
        newFolder.Parent = ReplicatedStorage
        remoteEventsFolder = newFolder
    end

    -- Ensure remoteEventsFolder is valid
    assert(remoteEventsFolder, "Failed to create RemoteEvents folder")

    -- Game control events
    local gameStartEvent = Instance.new("RemoteEvent")
    gameStartEvent.Name = "GameStart"
    gameStartEvent.Parent = remoteEventsFolder
    self.remoteEvents.GameStart = gameStartEvent

    local gameEndEvent = Instance.new("RemoteEvent")
    gameEndEvent.Name = "GameEnd"
    gameEndEvent.Parent = remoteEventsFolder
    self.remoteEvents.GameEnd = gameEndEvent

    local gameRestartEvent = Instance.new("RemoteEvent")
    gameRestartEvent.Name = "GameRestart"
    gameRestartEvent.Parent = remoteEventsFolder
    self.remoteEvents.GameRestart = gameRestartEvent

    -- Player action events
    local playerCollisionEvent = Instance.new("RemoteEvent")
    playerCollisionEvent.Name = "PlayerCollision"
    playerCollisionEvent.Parent = remoteEventsFolder
    self.remoteEvents.PlayerCollision = playerCollisionEvent

    local coinCollectedEvent = Instance.new("RemoteEvent")
    coinCollectedEvent.Name = "CoinCollected"
    coinCollectedEvent.Parent = remoteEventsFolder
    self.remoteEvents.CoinCollected = coinCollectedEvent

    local powerUpCollectedEvent = Instance.new("RemoteEvent")
    powerUpCollectedEvent.Name = "PowerUpCollected"
    powerUpCollectedEvent.Parent = remoteEventsFolder
    self.remoteEvents.PowerUpCollected = powerUpCollectedEvent

    -- Score update event
    local scoreUpdateEvent = Instance.new("RemoteEvent")
    scoreUpdateEvent.Name = "ScoreUpdate"
    scoreUpdateEvent.Parent = remoteEventsFolder
    self.remoteEvents.ScoreUpdate = scoreUpdateEvent

    -- Connect event handlers
    self:connectEventHandlers()

    print("🎮 Game Loop Manager - Remote Events Setup Complete")
end

-- Connect Remote Event Handlers
function GameLoopManager:connectEventHandlers()
    -- Game start request
    self.remoteEvents.GameStart.OnServerEvent:Connect(function(player)
        self:startGame(player)
    end)

    -- Game restart request
    self.remoteEvents.GameRestart.OnServerEvent:Connect(function(player)
        self:restartGame(player)
    end)

    -- Player collision with obstacle
    self.remoteEvents.PlayerCollision.OnServerEvent:Connect(function(player, obstacleType)
        self:handlePlayerCollision(player, obstacleType)
    end)

    -- Coin collected
    self.remoteEvents.CoinCollected.OnServerEvent:Connect(function(player, coinValue)
        self:handleCoinCollected(player, coinValue or 10)
    end)

    -- Power-up collected
    self.remoteEvents.PowerUpCollected.OnServerEvent:Connect(function(player, powerUpType)
        self:handlePowerUpCollected(player, powerUpType)
    end)

    print("🎮 Event handlers connected")
end

-- Setup player connections for join/leave events
function GameLoopManager:setupPlayerConnections()
    Players.PlayerAdded:Connect(function(player)
        self:onPlayerJoined(player)
    end)

    Players.PlayerRemoving:Connect(function(player)
        self:onPlayerLeaving(player)
    end)
end

-- Handle player joining
function GameLoopManager:onPlayerJoined(player: Player)
    print(`🎮 Player {player.Name} joined the game`)

    -- Initialize player data in leaderstats
    local leaderstats = Instance.new("Folder")
    leaderstats.Name = "leaderstats"
    leaderstats.Parent = player

    local score = Instance.new("IntValue")
    score.Name = "Score"
    score.Value = 0
    score.Parent = leaderstats

    local coins = Instance.new("IntValue")
    coins.Name = "Coins"
    coins.Value = 0
    coins.Parent = leaderstats

    local distance = Instance.new("IntValue")
    distance.Name = "Distance"
    distance.Value = 0
    distance.Parent = leaderstats

    -- Send current game state to player
    self:sendGameStateToPlayer(player)
end

-- Handle player leaving
function GameLoopManager:onPlayerLeaving(player: Player)
    print(`🎮 Player {player.Name} left the game`)

    -- Remove player from current session if active
    if self.currentSession then
        for i, playerData: PlayerGameData in ipairs(self.currentSession.players) do
            if playerData.player == player then
                table.remove(self.currentSession.players, i)
                break
            end
        end

        -- End game if no players left
        if #self.currentSession.players == 0 then
            self:endGame("No players remaining")
        end
    end
end

-- Start a new game session
function GameLoopManager:startGame(requestingPlayer: Player)
    if self.gameState == GameState.PLAYING then
        print(`🎮 Game already in progress - {requestingPlayer.Name} cannot start`)
        return
    end

    print(`🎮 Starting new game session - requested by {requestingPlayer.Name}`)

    -- Create new session
    local sessionId = tostring(tick())
    self.currentSession = {
        sessionId = sessionId,
        state = GameState.STARTING,
        startTime = tick(),
        endTime = nil,
        players = {},
        worldGenerator = nil,
        currentSpeed = 20,
        difficulty = 1,
    }

    -- Add all current players to session
    for _, player in ipairs(Players:GetPlayers()) do
        local playerData: PlayerGameData = {
            player = player,
            score = 0,
            isAlive = true,
            startTime = tick(),
            endTime = nil,
            distance = 0,
            coinsCollected = 0,
            powerUpsUsed = 0,
        }
        if self.currentSession then
            table.insert(self.currentSession.players, playerData)
        end

        -- Reset player stats (leaderstats prüfen und erstellen falls nötig)
        local leaderstats = player:FindFirstChild("leaderstats")
        if leaderstats then
            local scoreValue = leaderstats:FindFirstChild("Score") :: IntValue?
            local coinsValue = leaderstats:FindFirstChild("Coins") :: IntValue?
            local distanceValue = leaderstats:FindFirstChild("Distance") :: IntValue?

            if scoreValue then
                scoreValue.Value = 0
            end
            if coinsValue then
                coinsValue.Value = 0
            end
            if distanceValue then
                distanceValue.Value = 0
            end
        end
    end

    -- Update game state
    self.gameState = GameState.PLAYING
    if self.currentSession then
        self.currentSession.state = GameState.PLAYING
    end

    -- Initialize world generator
    self:initializeWorldGenerator()

    -- Start game loop
    self:startGameLoop()

    -- Notify all clients
    self.remoteEvents.GameStart:FireAllClients({
        sessionId = sessionId,
        startTime = self.currentSession.startTime,
    })

    print(`🎮 Game session {sessionId} started with {#self.currentSession.players} players`)
end

-- Initialize world generator
function GameLoopManager:initializeWorldGenerator()
    -- This will be connected to DynamicWorldGenerator when integrated
    print("🌍 World Generator initialized")

    -- For now, create basic world elements
    task.spawn(function()
        self:createBasicGameWorld()
    end)
end

-- Create basic game world
function GameLoopManager:createBasicGameWorld()
    local workspace = game:GetService("Workspace")

    -- Create spawn platform
    local spawnPlatform = Instance.new("Part")
    spawnPlatform.Name = "SpawnPlatform"
    spawnPlatform.Size = Vector3.new(50, 2, 50)
    spawnPlatform.Position = Vector3.new(0, 0, 0)
    spawnPlatform.Material = Enum.Material.Concrete
    spawnPlatform.BrickColor = BrickColor.new("Dark grey") -- Korrekte BrickColor Bezeichnung
    spawnPlatform.Anchored = true
    spawnPlatform.Parent = workspace

    -- Create initial track segments
    for i = 1, 20 do
        local segment = Instance.new("Part")
        segment.Name = `TrackSegment_{i}`
        segment.Size = Vector3.new(24, 1, 20)
        segment.Position = Vector3.new(0, -1, i * 20)
        segment.Material = Enum.Material.Asphalt
        segment.BrickColor = BrickColor.new("Really black")
        segment.Anchored = true
        segment.Parent = workspace
    end

    print("🌍 Basic game world created")
end

-- Start main game loop
function GameLoopManager:startGameLoop()
    if self.updateConnection then
        self.updateConnection:Disconnect()
    end

    self.updateConnection = RunService.Heartbeat:Connect(function(deltaTime)
        if self.gameState == GameState.PLAYING and self.currentSession then
            self:updateGameSession(deltaTime)
        end
    end)

    print("🎮 Game loop started")
end

-- Update game session
function GameLoopManager:updateGameSession(deltaTime: number)
    if not self.currentSession then
        return
    end

    local session = self.currentSession
    local currentTime = tick()
    local elapsedTime = currentTime - session.startTime

    -- Update game difficulty over time
    session.difficulty = math.min(5, math.floor(elapsedTime / 30) + 1)
    session.currentSpeed = 20 + (session.difficulty * 5)

    -- Update player distances and scores
    for _, playerData in ipairs(session.players) do
        if playerData.isAlive then
            -- Calculate distance based on time
            local playerElapsed = currentTime - playerData.startTime
            playerData.distance = math.floor(playerElapsed * session.currentSpeed / 10)

            -- Calculate score (distance + coins)
            playerData.score = (playerData.distance :: number) + ((playerData.coinsCollected :: number) * 10)

            -- Update leaderstats
            local leaderstats = playerData.player:FindFirstChild("leaderstats")
            if leaderstats then
                local scoreValue = leaderstats:FindFirstChild("Score") :: IntValue?
                local distanceValue = leaderstats:FindFirstChild("Distance") :: IntValue?
                local coinsValue = leaderstats:FindFirstChild("Coins") :: IntValue?

                if scoreValue then
                    scoreValue.Value = playerData.score
                end
                if distanceValue then
                    distanceValue.Value = playerData.distance
                end
                if coinsValue then
                    coinsValue.Value = playerData.coinsCollected
                end
            end
        end
    end

    -- Check if all players are dead
    local alivePlayers = 0
    for _, playerData in ipairs(session.players) do
        if playerData.isAlive then
            alivePlayers = alivePlayers + 1
        end
    end

    if alivePlayers == 0 then
        self:endGame("All players eliminated")
    end
end

-- Handle player collision with obstacle
function GameLoopManager:handlePlayerCollision(player: Player, obstacleType: string)
    if not self.currentSession then
        return
    end

    local playerData = self:getPlayerData(player)
    if not playerData or not playerData.isAlive then
        return
    end

    print(`💥 {player.Name} collided with {obstacleType}`)

    -- Mark player as dead
    playerData.isAlive = false
    playerData.endTime = tick()

    -- Notify client
    self.remoteEvents.GameEnd:FireClient(player, {
        reason = "collision",
        obstacleType = obstacleType,
        finalScore = playerData.score,
        distance = playerData.distance,
        coinsCollected = playerData.coinsCollected,
    })

    -- Check if game should end
    local alivePlayers = 0
    for _, pData in ipairs(self.currentSession.players) do
        if pData.isAlive then
            alivePlayers = alivePlayers + 1
        end
    end

    if alivePlayers == 0 then
        self:endGame("All players eliminated")
    end
end

-- Handle coin collection
function GameLoopManager:handleCoinCollected(player: Player, coinValue: number)
    if not self.currentSession then
        return
    end

    local playerData = self:getPlayerData(player)
    if not playerData or not playerData.isAlive then
        return
    end

    playerData.coinsCollected = (playerData.coinsCollected :: number) + 1
    playerData.score = (playerData.score :: number) + (coinValue :: number)

    print(`💰 {player.Name} collected coin - Total: {playerData.coinsCollected}`)

    -- Update leaderstats
    local leaderstats = player:FindFirstChild("leaderstats")
    if leaderstats then
        local coinsValue = leaderstats:FindFirstChild("Coins") :: IntValue?
        local scoreValue = leaderstats:FindFirstChild("Score") :: IntValue?

        if coinsValue then
            coinsValue.Value = playerData.coinsCollected
        end
        if scoreValue then
            scoreValue.Value = playerData.score
        end
    end

    -- Notify client
    self.remoteEvents.ScoreUpdate:FireClient(player, {
        score = playerData.score,
        coins = playerData.coinsCollected,
        coinValue = coinValue,
    })
end

-- Handle power-up collection
function GameLoopManager:handlePowerUpCollected(player: Player, powerUpType: string)
    if not self.currentSession then
        return
    end

    local playerData = self:getPlayerData(player)
    if not playerData or not playerData.isAlive then
        return
    end

    playerData.powerUpsUsed = (playerData.powerUpsUsed :: number) + 1

    print(`⚡ {player.Name} collected {powerUpType} power-up`)

    -- Apply power-up effects (to be implemented in PlayerController)
    self.remoteEvents.PowerUpCollected:FireClient(player, {
        powerUpType = powerUpType,
        duration = self:getPowerUpDuration(powerUpType),
    })
end

-- Get power-up duration
function GameLoopManager:getPowerUpDuration(powerUpType: string): number
    local durations = {
        JETPACK = 5,
        MAGNET = 8,
        SHIELD = 10,
        SPEED_BOOST = 6,
    }

    return durations[powerUpType] or 5
end

-- Get player data from session
function GameLoopManager:getPlayerData(player: Player): PlayerGameData?
    if not self.currentSession then
        return nil
    end

    for _, playerData: PlayerGameData in ipairs(self.currentSession.players) do
        if playerData.player == player then
            return playerData
        end
    end

    return nil
end

-- End current game session
function GameLoopManager:endGame(reason: string)
    if not self.currentSession then
        return
    end

    print(`🎮 Ending game session: {reason}`)

    self.gameState = GameState.GAME_OVER
    if self.currentSession then
        self.currentSession.state = GameState.GAME_OVER
        self.currentSession.endTime = tick()
    end

    -- Stop game loop
    local connection = self.updateConnection
    if connection then
        connection:Disconnect()
    end
    (self :: any).updateConnection = nil

    -- Calculate final scores and send results
    local results = {}
    for _, playerData in ipairs(self.currentSession.players) do
        local result = {
            playerName = playerData.player.Name,
            score = playerData.score,
            distance = playerData.distance,
            coinsCollected = playerData.coinsCollected,
            powerUpsUsed = playerData.powerUpsUsed,
            survivalTime = (playerData.endTime or self.currentSession.endTime) - playerData.startTime,
        }
        table.insert(results, result)
    end

    -- Sort by score
    table.sort(results, function(a: any, b: any)
        return (a.score :: number) > (b.score :: number)
    end)

    -- Notify all clients
    self.remoteEvents.GameEnd:FireAllClients({
        reason = reason,
        results = results,
        sessionDuration = self.currentSession.endTime - self.currentSession.startTime,
    })

    print(
        `🎮 Game session ended - Duration: {math.floor(self.currentSession.endTime - self.currentSession.startTime)}s`
    )
end

-- Restart game
function GameLoopManager:restartGame(requestingPlayer: Player)
    print(`🔄 Game restart requested by {requestingPlayer.Name}`)

    -- End current game if active
    if self.currentSession then
        self:endGame("Game restarted")
    end

    -- Wait a moment for cleanup
    task.wait(1)

    -- Start new game
    self:startGame(requestingPlayer)
end

-- Send current game state to player
function GameLoopManager:sendGameStateToPlayer(player: Player)
    local gameStateData = {
        state = self.gameState,
        sessionActive = self.currentSession ~= nil,
        sessionId = self.currentSession and self.currentSession.sessionId or nil,
    }

    -- Send via a dedicated event or existing one
    if self.remoteEvents.ScoreUpdate then
        self.remoteEvents.ScoreUpdate:FireClient(player, gameStateData)
    end
end

-- Get current game state
function GameLoopManager:getGameState(): string
    return self.gameState
end

-- Get current session info
function GameLoopManager:getCurrentSession()
    return self.currentSession
end

-- Cleanup on destruction
function GameLoopManager:cleanup()
    local connection = self.updateConnection
    if connection then
        connection:Disconnect()
    end
    (self :: any).updateConnection = nil

    -- Clean up remote events
    for _, remoteEvent in pairs(self.remoteEvents) do
        if remoteEvent and remoteEvent.Parent then
            remoteEvent:Destroy()
        end
    end

    print("🎮 Game Loop Manager cleaned up")
end

-- Diese Datei enthält die Hauptspiellogik für das Spiel

-- Initialisierung der Spielschleife
function GameLoopManager:Start()
    -- Spiel-Update-Logik hier
end

-- Funktion zum Stoppen der Spielschleife
function GameLoopManager:Stop()
    -- Logik zum Stoppen der Spielschleife
end

return GameLoopManager
