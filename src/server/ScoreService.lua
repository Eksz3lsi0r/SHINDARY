--!nocheck
-- ScoreService.lua - Handle scoring and collectibles
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local SharedFolder = ReplicatedStorage:WaitForChild("Shared")
local GameConfig = require(SharedFolder:WaitForChild("GameConfig"))
local GameState = require(SharedFolder:WaitForChild("GameState"))

local ScoreService = {}

-- Initialize ScoreService
function ScoreService:Initialize()
    print("[ScoreService] Score tracking system initialized")
end

-- Start tracking player score
function ScoreService:StartTrackingPlayer(player)
    print("[ScoreService] Started tracking score for:", player.Name)
end

-- Stop tracking player score
function ScoreService:StopTrackingPlayer(player)
    print("[ScoreService] Stopped tracking score for:", player.Name)
end

-- Process collectible for a specific player
function ScoreService:ProcessCollectible(player, collectibleType, value)
    local scoreGained = 0

    print("[ScoreService] Processing collectible for", player.Name, ":", collectibleType, "value:", value)

    -- Handle both "COIN" and "Coin" formats
    local normalizedType = string.upper(collectibleType)

    if normalizedType == "COIN" then
        scoreGained = GameConfig.Scores.coin * (value or 1)
        print("[ScoreService] Coin collected - base score:", GameConfig.Scores.coin)
    elseif normalizedType == "GEM" then
        scoreGained = GameConfig.Scores.gem * (value or 1)
        print("[ScoreService] Gem collected - base score:", GameConfig.Scores.gem)
    elseif normalizedType == "POWER_UP" or normalizedType == "POWERUP" then
        scoreGained = GameConfig.Scores.powerUp * (value or 1)
        print("[ScoreService] Power-up collected - base score:", GameConfig.Scores.powerUp)
    else
        warn("[ScoreService] Unknown collectible type:", collectibleType)
    end

    -- Apply score multiplier based on current speed
    local speedMultiplier = math.min(GameState.SessionData.currentSpeed / GameConfig.Gameplay.baseSpeed, 2)
    scoreGained = math.floor(scoreGained * speedMultiplier)

    print("[ScoreService] Final score after multiplier:", scoreGained, "multiplier:", speedMultiplier)

    return scoreGained
end

-- Process obstacle hit
function ScoreService:ProcessObstacleHit(player, obstacleType)
    print("[ScoreService] Player", player.Name, "hit obstacle:", obstacleType)
end

-- Calculate final score
function ScoreService:CalculateFinalScore(player)
    print("[ScoreService] Calculating final score for:", player.Name)
    return GameState.SessionData.currentScore or 0
end

-- Get session stats
function ScoreService:GetSessionStats(player)
    return {
        coinsCollected = 0,
        gemsCollected = 0,
        finalScore = 0,
    }
end

-- Process distance for scoring
function ScoreService:ProcessDistance(player, distance)
    if not player or not distance then
        warn("[ScoreService] Invalid parameters for ProcessDistance")
        return
    end

    -- Calculate distance-based score
    local distanceScore = self:CalculateDistanceScore(distance)

    print("[ScoreService] Processing distance for", player.Name, "- Distance:", distance, "Score:", distanceScore)

    -- Check for distance milestones
    self:CheckDistanceMilestones(player, distance)

    return distanceScore
end

-- Check distance milestones
function ScoreService:CheckDistanceMilestones(player, distance)
    if not player or not distance then
        return
    end

    -- Check for distance-based achievements/milestones
    local milestones = { 100, 500, 1000, 2500, 5000, 10000 }

    for _, milestone in ipairs(milestones) do
        if distance >= milestone and (distance - 1) < milestone then
            print("[ScoreService] 🎉 Distance milestone reached:", milestone, "by", player.Name)
            -- Here you could trigger achievements, bonus points, etc.
        end
    end
end

-- Process collectible and return score value (legacy compatibility)
function ScoreService:ProcessCollectible_Legacy(collectibleType, value)
    local scoreGained = 0

    print("[ScoreService] Processing collectible:", collectibleType, "value:", value)

    if collectibleType == GameState.CollectibleTypes.COIN then
        scoreGained = GameConfig.Scores.coin * (value or 1)
        print("[ScoreService] Coin collected - base score:", GameConfig.Scores.coin)
    elseif collectibleType == GameState.CollectibleTypes.GEM then
        scoreGained = GameConfig.Scores.gem * (value or 1)
        print("[ScoreService] Gem collected - base score:", GameConfig.Scores.gem)
    elseif collectibleType == GameState.CollectibleTypes.POWER_UP then
        scoreGained = GameConfig.Scores.powerUp * (value or 1)
        print("[ScoreService] Power-up collected - base score:", GameConfig.Scores.powerUp)
    else
        warn("[ScoreService] Unknown collectible type:", collectibleType)
    end

    -- Apply score multiplier based on current speed
    local speedMultiplier = math.min(GameState.SessionData.currentSpeed / GameConfig.Gameplay.baseSpeed, 2)
    scoreGained = math.floor(scoreGained * speedMultiplier)

    print("[ScoreService] Final score after multiplier:", scoreGained, "multiplier:", speedMultiplier)

    return scoreGained
end
-- Calculate combo multiplier
function ScoreService:CalculateComboMultiplier(consecutiveCollections)
    local multiplier = 1
    if consecutiveCollections >= 5 then
        multiplier = 1.5
    elseif consecutiveCollections >= 10 then
        multiplier = 2
    elseif consecutiveCollections >= 20 then
        multiplier = 3
    end
    return multiplier
end

-- Calculate score for distance traveled
function ScoreService:CalculateDistanceScore(distance)
    return math.floor(distance * GameConfig.Scores.distanceMultiplier)
end

-- Get score breakdown for end game screen
function ScoreService:GetScoreBreakdown(sessionData)
    return {
        baseScore = sessionData.currentScore or 0,
        distanceBonus = self:CalculateDistanceScore(sessionData.currentDistance or 0),
        collectibleBonus = (sessionData.collectiblesGathered or 0) * 5,
        survivalBonus = math.max(0, 100 - (sessionData.obstaclesHit or 0) * 10),
        speedBonus = math.floor(
            (sessionData.currentSpeed or GameConfig.Gameplay.baseSpeed) - GameConfig.Gameplay.baseSpeed
        ),
    }
end

return ScoreService
