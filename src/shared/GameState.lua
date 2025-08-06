-- GameState.lua - Shared game state management
local GameState = {}

-- Game states enumeration
GameState.States = {
    MENU = "Menu",
    PLAYING = "Playing",
    PAUSED = "Paused",
    GAME_OVER = "GameOver",
    LOADING = "Loading",
}

-- Player data structure
GameState.DefaultPlayerData = {
    score = 0,
    highScore = 0,
    coins = 0,
    gems = 0,
    distance = 0,
    powerUpsCollected = 0,
    gamesPlayed = 0,
    totalPlayTime = 0,
}

-- Current game session data
GameState.SessionData = {
    currentScore = 0,
    currentDistance = 0,
    currentSpeed = 0,
    powerUpsActive = {},
    obstaclesHit = 0,
    collectiblesGathered = 0,
    startTime = 0,
    endTime = 0,
}

-- Power-up types
GameState.PowerUpTypes = {
    SPEED_BOOST = "SpeedBoost",
    SHIELD = "Shield",
    MAGNET = "Magnet",
    JUMP_BOOST = "JumpBoost",
}

-- Collectible types
GameState.CollectibleTypes = {
    COIN = "Coin",
    GEM = "Gem",
    POWER_UP = "PowerUp",
}

-- Obstacle types
GameState.ObstacleTypes = {
    BARRIER = "Barrier",
    SPIKE = "Spike",
    MOVING_PLATFORM = "MovingPlatform",
    GAP = "Gap",
}

-- Reset session data
function GameState.ResetSession()
    GameState.SessionData = {
        currentScore = 0,
        currentDistance = 0,
        currentSpeed = 0,
        powerUpsActive = {},
        obstaclesHit = 0,
        collectiblesGathered = 0,
        startTime = tick(),
        endTime = 0,
    }
end

-- Check if power-up is active
function GameState.IsPowerUpActive(powerUpType)
    return GameState.SessionData.powerUpsActive[powerUpType] ~= nil
        and GameState.SessionData.powerUpsActive[powerUpType] > tick()
end

-- Activate power-up
function GameState.ActivatePowerUp(powerUpType, duration)
    GameState.SessionData.powerUpsActive[powerUpType] = tick() + duration
end

-- Clean up expired power-ups
function GameState.CleanupExpiredPowerUps()
    local currentTime = tick()
    for powerUpType, expireTime in pairs(GameState.SessionData.powerUpsActive) do
        if expireTime <= currentTime then
            GameState.SessionData.powerUpsActive[powerUpType] = nil
        end
    end
end

-- Calculate final score with bonuses
function GameState.CalculateFinalScore()
    local baseScore = GameState.SessionData.currentScore
    local distanceBonus = math.floor(GameState.SessionData.currentDistance / 10)
    local collectibleBonus = GameState.SessionData.collectiblesGathered * 5
    local survivalBonus = math.max(0, 100 - GameState.SessionData.obstaclesHit * 10)

    return baseScore + distanceBonus + collectibleBonus + survivalBonus
end

return GameState
