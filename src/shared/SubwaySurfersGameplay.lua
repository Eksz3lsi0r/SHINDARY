-- SubwaySurfersGameplay.lua - Subway Surfers inspired gameplay mechanics
local SubwaySurfersGameplay = {}

-- Track/Lane system (like Subway Surfers' 3-lane system)
SubwaySurfersGameplay.Lanes = {
    LEFT = -1,
    CENTER = 0,
    RIGHT = 1,
}

SubwaySurfersGameplay.LanePositions = {
    [-1] = -8, -- Left lane X position
    [0] = 0, -- Center lane X position
    [1] = 8, -- Right lane X position
}

-- Player movement states
SubwaySurfersGameplay.MovementStates = {
    RUNNING = "Running",
    JUMPING = "Jumping",
    ROLLING = "Rolling",
    SLIDING = "Sliding",
    FALLING = "Falling",
}

-- Power-ups (Subway Surfers style)
SubwaySurfersGameplay.PowerUps = {
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

-- Obstacle types (Subway Surfers inspired)
SubwaySurfersGameplay.ObstacleTypes = {
    TRAIN = {
        name = "Train",
        height = 6,
        width = 4,
        canJumpOver = false,
        canSlideUnder = false,
        canDodge = true,
    },
    BARRIER = {
        name = "Barrier",
        height = 3,
        width = 2,
        canJumpOver = true,
        canSlideUnder = false,
        canDodge = true,
    },
    TUNNEL_ENTRANCE = {
        name = "Tunnel",
        height = 2,
        width = 8,
        canJumpOver = false,
        canSlideUnder = true,
        canDodge = false,
    },
    SIGN_POST = {
        name = "Sign",
        height = 4,
        width = 1,
        canJumpOver = true,
        canSlideUnder = true,
        canDodge = true,
    },
}

-- Collectible types (Subway Surfers style)
SubwaySurfersGameplay.CollectibleTypes = {
    COIN = {
        name = "Coin",
        value = 1,
        scoreValue = 10,
        color = Color3.fromRGB(255, 215, 0),
        size = Vector3.new(1, 1, 0.2),
        rotationSpeed = 2,
    },
    COIN_LINE = {
        name = "CoinLine",
        value = 5,
        scoreValue = 50,
        color = Color3.fromRGB(255, 215, 0),
        size = Vector3.new(1, 1, 0.2),
        rotationSpeed = 2,
        spacing = 3,
    },
    KEY = {
        name = "Key",
        value = 1,
        scoreValue = 0,
        color = Color3.fromRGB(0, 191, 255),
        size = Vector3.new(1.5, 2, 0.3),
        rotationSpeed = 1.5,
        special = true,
    },
    MYSTERY_BOX = {
        name = "MysteryBox",
        value = 1,
        scoreValue = 100,
        color = Color3.fromRGB(138, 43, 226),
        size = Vector3.new(2, 2, 2),
        rotationSpeed = 0.8,
        special = true,
    },
}

-- Mission system (like Subway Surfers daily missions)
SubwaySurfersGameplay.Missions = {
    {
        id = "collect_coins",
        name = "Coin Collector",
        description = "Collect 100 coins in a single run",
        target = 100,
        reward = 500,
        type = "collect",
    },
    {
        id = "jump_obstacles",
        name = "Leap Frog",
        description = "Jump over 20 obstacles",
        target = 20,
        reward = 300,
        type = "action",
    },
    {
        id = "run_distance",
        name = "Marathon Runner",
        description = "Run 2000 meters",
        target = 2000,
        reward = 750,
        type = "distance",
    },
    {
        id = "use_powerups",
        name = "Power Player",
        description = "Use 5 power-ups in one run",
        target = 5,
        reward = 400,
        type = "powerup",
    },
}

-- Character abilities (Subway Surfers movement)
SubwaySurfersGameplay.Abilities = {
    DOUBLE_TAP_ROLL = {
        name = "Roll",
        cooldown = 1,
        description = "Roll under low obstacles",
    },
    SWIPE_DODGE = {
        name = "Lane Switch",
        cooldown = 0.3,
        description = "Quickly move between lanes",
    },
    HOVER_BOARD = {
        name = "Hoverboard",
        duration = 30,
        description = "Temporary invincibility and speed boost",
        consumable = true,
    },
}

-- World generation patterns (Subway Surfers style track segments)
SubwaySurfersGameplay.TrackPatterns = {
    {
        name = "CoinTunnel",
        length = 50,
        difficulty = 1,
        coins = "line",
        obstacles = { "TUNNEL_ENTRANCE" },
    },
    {
        name = "TrainDodge",
        length = 30,
        difficulty = 3,
        coins = "scattered",
        obstacles = { "TRAIN", "BARRIER" },
    },
    {
        name = "PowerUpRun",
        length = 40,
        difficulty = 2,
        coins = "bonus",
        powerup = true,
        obstacles = { "SIGN_POST" },
    },
    {
        name = "Challenge",
        length = 60,
        difficulty = 4,
        coins = "high_reward",
        obstacles = { "TRAIN", "BARRIER", "TUNNEL_ENTRANCE" },
    },
}

-- Speed progression (like Subway Surfers increasing difficulty)
SubwaySurfersGameplay.SpeedProgression = {
    { distance = 0, speed = 12, spawnRate = 0.5 },
    { distance = 500, speed = 15, spawnRate = 0.7 },
    { distance = 1000, speed = 18, spawnRate = 0.9 },
    { distance = 2000, speed = 22, spawnRate = 1.2 },
    { distance = 3500, speed = 25, spawnRate = 1.5 },
    { distance = 5000, speed = 28, spawnRate = 1.8 },
}

-- Get current lane position for player
function SubwaySurfersGameplay.GetLanePosition(lane)
    return SubwaySurfersGameplay.LanePositions[lane] or 0
end

-- Check if obstacle can be avoided by specific action
function SubwaySurfersGameplay.CanAvoidObstacle(obstacleType, action)
    local obstacle = SubwaySurfersGameplay.ObstacleTypes[obstacleType]
    if not obstacle then
        return false
    end

    if action == "jump" then
        return obstacle.canJumpOver
    elseif action == "slide" then
        return obstacle.canSlideUnder
    elseif action == "dodge" then
        return obstacle.canDodge
    end

    return false
end

-- Get speed settings for current distance
function SubwaySurfersGameplay.GetSpeedForDistance(distance)
    local settings = SubwaySurfersGameplay.SpeedProgression[1]

    for _, speedSetting in ipairs(SubwaySurfersGameplay.SpeedProgression) do
        if distance >= speedSetting.distance then
            settings = speedSetting
        else
            break
        end
    end

    return settings
end

-- Calculate score multiplier based on current state
function SubwaySurfersGameplay.CalculateScoreMultiplier(powerUps: any?, distance: any): number
    local multiplier: number = 1
    local distanceNum: number = tonumber(distance) or 0

    -- Distance bonus
    multiplier = multiplier + math.floor(distanceNum / 1000) * 0.1

    -- Power-up multiplier
    if powerUps and powerUps.MULTIPLIER then
        multiplier = multiplier * 2
    end

    return math.min(multiplier, 5) -- Cap at 5x
end

return SubwaySurfersGameplay
