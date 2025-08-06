-- GameConfig.lua - Shared configuration for the endless runner game
local GameConfig = {}

--[[
Type definitions for reference (Luau types when supported):
- PlayerConfig: { walkSpeed: number, jumpPower: number, jumpHeight: number, health: number, invulnerabilityTime: number }
- GameplayConfig: { baseSpeed: number, speedIncrement: number, maxSpeed: number, obstacleSpawnRate: number, collectibleSpawnRate: number, scoreMultiplier: number }
- WorldConfig: { platformWidth: number, platformLength: number, platformHeight: number, despawnDistance: number, spawnDistance: number }
--]]

-- Player settings
GameConfig.Player = {
    walkSpeed = 16,
    jumpPower = 50,
    jumpHeight = 20,
    health = 100,
    invulnerabilityTime = 2, -- seconds
}

-- Gameplay settings
GameConfig.Gameplay = {
    baseSpeed = 10,
    speedIncrement = 0.5,
    maxSpeed = 25,
    obstacleSpawnRate = 0.8, -- obstacles per second
    collectibleSpawnRate = 0.3, -- collectibles per second
    scoreMultiplier = 10,
}

-- World generation settings
GameConfig.World = {
    platformWidth = 20,
    platformLength = 50,
    platformHeight = 2,
    despawnDistance = 100, -- units behind player
    spawnDistance = 200, -- units ahead of player
}

-- Score values
GameConfig.Scores = {
    coin = 10,
    gem = 50,
    powerUp = 25,
    distanceMultiplier = 1, -- points per stud traveled
}

-- Power-up durations (in seconds)
GameConfig.PowerUps = {
    -- Legacy power-ups
    speedBoost = 5,
    shield = 8,
    magnet = 6,
    jumpBoost = 4,

    -- Subway Surfers style power-ups
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

-- Visual effects settings
GameConfig.Effects = {
    coinSpinSpeed = 2, -- rotations per second
    gemPulseSpeed = 1.5,
    particleLifetime = 2,
    cameraShakeIntensity = 0.5,
}

-- Audio settings
GameConfig.Audio = {
    masterVolume = 0.8,
    musicVolume = 0.6,
    sfxVolume = 0.7,
}

return GameConfig
