-- ObstacleService.lua - Subway Surfers inspired obstacle spawning system
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local Workspace = game:GetService("Workspace")

local SharedFolder = ReplicatedStorage:WaitForChild("Shared")
local GameConfig = require(SharedFolder:WaitForChild("GameConfig"))
local SubwaySurfersGameplay = require(SharedFolder:WaitForChild("SubwaySurfersGameplay"))

local ObstacleService = {}
ObstacleService.ActiveObstacles = {}
ObstacleService.ActiveCollectibles = {}
ObstacleService.SpawnPosition = 0
ObstacleService.LastSpawnTime = 0
ObstacleService.IsActive = false

-- Initialize obstacle service
function ObstacleService:Initialize()
    self.SpawnPosition = GameConfig.World.spawnDistance
    self.LastSpawnTime = tick()

    -- Create obstacle containers
    self:CreateObstacleContainers()

    print("[ObstacleService] Obstacle service initialized")
end

-- Create containers for obstacles
function ObstacleService:CreateObstacleContainers()
    local gameWorld = Workspace:FindFirstChild("GameWorld")
    if not gameWorld then
        gameWorld = Instance.new("Folder")
        gameWorld.Name = "GameWorld"
        gameWorld.Parent = Workspace
    end

    local obstacles = gameWorld:FindFirstChild("Obstacles")
    if not obstacles then
        obstacles = Instance.new("Folder")
        obstacles.Name = "Obstacles"
        obstacles.Parent = gameWorld
    end

    local collectibles = gameWorld:FindFirstChild("Collectibles")
    if not collectibles then
        collectibles = Instance.new("Folder")
        collectibles.Name = "Collectibles"
        collectibles.Parent = gameWorld
    end

    self.ObstacleContainer = obstacles
    self.CollectibleContainer = collectibles
end

-- Start spawning obstacles
function ObstacleService:StartSpawning()
    self.IsActive = true
    self.LastSpawnTime = tick()

    -- Connect spawning loop
    self.SpawnConnection = RunService.Heartbeat:Connect(function()
        self:UpdateSpawning()
    end)

    print("[ObstacleService] Started spawning obstacles")
end

-- Stop spawning obstacles
function ObstacleService:StopSpawning()
    self.IsActive = false

    if self.SpawnConnection then
        self.SpawnConnection:Disconnect()
        self.SpawnConnection = nil
    end

    print("[ObstacleService] Stopped spawning obstacles")
end

-- Update spawning logic
function ObstacleService:UpdateSpawning()
    if not self.IsActive then
        return
    end

    local currentTime = tick()
    local timeSinceLastSpawn = currentTime - self.LastSpawnTime

    -- Get current speed settings
    local speedSettings = SubwaySurfersGameplay.GetSpeedForDistance(self.SpawnPosition)
    local spawnInterval = 1 / speedSettings.spawnRate

    if timeSinceLastSpawn >= spawnInterval then
        self:SpawnObstaclePattern()
        self.LastSpawnTime = currentTime
    end

    -- Clean up distant obstacles
    self:CleanupDistantObstacles()
end

-- Spawn obstacle pattern
function ObstacleService:SpawnObstaclePattern()
    -- Choose random pattern based on difficulty
    local patterns = SubwaySurfersGameplay.TrackPatterns
    local pattern = patterns[math.random(1, #patterns)]

    -- Spawn obstacles for this pattern
    self:SpawnPatternObstacles(pattern)

    -- Spawn collectibles for this pattern
    self:SpawnPatternCollectibles(pattern)

    -- Update spawn position
    self.SpawnPosition = self.SpawnPosition + pattern.length
end

-- Spawn obstacles for a specific pattern
function ObstacleService:SpawnPatternObstacles(pattern)
    for i, obstacleType in ipairs(pattern.obstacles) do
        local obstacleData = SubwaySurfersGameplay.ObstacleTypes[obstacleType]
        if obstacleData then
            -- Choose random lane (avoid all lanes being blocked)
            local availableLanes = { -1, 0, 1 }
            local lane = availableLanes[math.random(1, #availableLanes)]

            -- Create obstacle
            local obstacle = self:CreateObstacle(obstacleType, obstacleData, lane)
            if obstacle then
                table.insert(self.ActiveObstacles, {
                    part = obstacle,
                    type = obstacleType,
                    lane = lane,
                    spawnZ = self.SpawnPosition,
                })
            end
        end
    end
end

-- Create physical obstacle
function ObstacleService:CreateObstacle(obstacleType, obstacleData, lane)
    local obstacle = Instance.new("Part")
    obstacle.Name = obstacleData.name
    obstacle.Size = Vector3.new(obstacleData.width, obstacleData.height, 2)
    obstacle.Material = Enum.Material.Concrete
    obstacle.BrickColor = BrickColor.new("Dark stone grey")
    obstacle.Anchored = true
    obstacle.CanCollide = true

    -- Position in lane
    local laneX = SubwaySurfersGameplay.GetLanePosition(lane)
    obstacle.Position = Vector3.new(laneX, obstacleData.height / 2, self.SpawnPosition)

    -- Add collision detection
    local function onTouched(hit)
        local humanoid = hit.Parent:FindFirstChild("Humanoid")
        if humanoid then
            self:HandleObstacleCollision(obstacle, obstacleType, humanoid.Parent)
        end
    end
    obstacle.Touched:Connect(onTouched)

    -- Add visual effects based on type
    if obstacleType == "TRAIN" then
        obstacle.BrickColor = BrickColor.new("Really red")
        -- Add train-like decorations
        local stripe = Instance.new("Part")
        stripe.Size = Vector3.new(obstacleData.width, 0.5, 2)
        stripe.Material = Enum.Material.Neon
        stripe.BrickColor = BrickColor.new("Bright yellow")
        stripe.Anchored = true
        stripe.CanCollide = false
        stripe.Position = obstacle.Position + Vector3.new(0, obstacleData.height / 3, 0)
        stripe.Parent = self.ObstacleContainer
    end

    obstacle.Parent = self.ObstacleContainer
    return obstacle
end

-- Spawn collectibles for pattern
function ObstacleService:SpawnPatternCollectibles(pattern)
    if pattern.coins == "line" then
        self:SpawnCoinLine()
    elseif pattern.coins == "scattered" then
        self:SpawnScatteredCoins()
    elseif pattern.coins == "bonus" then
        self:SpawnBonusCollectibles()
    end

    -- Spawn power-up if pattern includes it
    if pattern.powerup then
        self:SpawnPowerUp()
    end
end

-- Spawn line of coins
function ObstacleService:SpawnCoinLine()
    local coinData = SubwaySurfersGameplay.CollectibleTypes.COIN
    local lane = math.random(-1, 1) -- Random lane
    local laneX = SubwaySurfersGameplay.GetLanePosition(lane)

    for i = 1, 10 do
        local coin = self:CreateCollectible("COIN", coinData, laneX, self.SpawnPosition + (i * 3))
        if coin then
            table.insert(self.ActiveCollectibles, {
                part = coin,
                type = "COIN",
                lane = lane,
                spawnZ = self.SpawnPosition + (i * 3),
            })
        end
    end
end

-- Spawn scattered coins
function ObstacleService:SpawnScatteredCoins()
    local coinData = SubwaySurfersGameplay.CollectibleTypes.COIN

    for i = 1, 5 do
        local lane = math.random(-1, 1)
        local laneX = SubwaySurfersGameplay.GetLanePosition(lane)
        local zOffset = math.random(0, 30)

        local coin = self:CreateCollectible("COIN", coinData, laneX, self.SpawnPosition + zOffset)
        if coin then
            table.insert(self.ActiveCollectibles, {
                part = coin,
                type = "COIN",
                lane = lane,
                spawnZ = self.SpawnPosition + zOffset,
            })
        end
    end
end

-- Spawn bonus collectibles
function ObstacleService:SpawnBonusCollectibles()
    -- Spawn mystery box
    local boxData = SubwaySurfersGameplay.CollectibleTypes.MYSTERY_BOX
    local lane = math.random(-1, 1)
    local laneX = SubwaySurfersGameplay.GetLanePosition(lane)

    local mysteryBox = self:CreateCollectible("MYSTERY_BOX", boxData, laneX, self.SpawnPosition + 15)
    if mysteryBox then
        table.insert(self.ActiveCollectibles, {
            part = mysteryBox,
            type = "MYSTERY_BOX",
            lane = lane,
            spawnZ = self.SpawnPosition + 15,
        })
    end
end

-- Spawn power-up
function ObstacleService:SpawnPowerUp()
    local powerUpTypes = { "JETPACK", "SUPER_SNEAKERS", "COIN_MAGNET", "MULTIPLIER" }
    local powerUpType = powerUpTypes[math.random(1, #powerUpTypes)]
    local powerUpData = SubwaySurfersGameplay.PowerUps[powerUpType]

    local lane = math.random(-1, 1)
    local laneX = SubwaySurfersGameplay.GetLanePosition(lane)

    local powerUp = self:CreatePowerUp(powerUpType, powerUpData, laneX, self.SpawnPosition + 20)
    if powerUp then
        table.insert(self.ActiveCollectibles, {
            part = powerUp,
            type = powerUpType,
            lane = lane,
            spawnZ = self.SpawnPosition + 20,
        })
    end
end

-- Create physical collectible
function ObstacleService:CreateCollectible(collectibleType, collectibleData, x, z)
    local collectible = Instance.new("Part")
    collectible.Name = collectibleData.name
    collectible.Size = collectibleData.size or Vector3.new(1, 1, 1)
    collectible.Material = Enum.Material.Neon
    collectible.BrickColor = BrickColor.new(collectibleData.color)
    collectible.Anchored = true
    collectible.CanCollide = false
    collectible.Shape = Enum.PartType.Cylinder

    -- Position
    collectible.Position = Vector3.new(x, 3, z)

    -- Add spinning animation with nil check
    local rotationSpeed = collectibleData.rotationSpeed or 1 -- Default to 1 if nil
    local spinTween = TweenService:Create(
        collectible,
        TweenInfo.new(1 / rotationSpeed, Enum.EasingStyle.Linear, Enum.EasingDirection.InOut, -1),
        { Rotation = Vector3.new(0, 360, 0) }
    )
    spinTween:Play()

    -- Add collection detection
    local function onTouched(hit)
        local parent = hit.Parent
        if not parent then
            return
        end

        local humanoid = parent:FindFirstChild("Humanoid")
        if humanoid then
            self:HandleCollectibleCollection(collectible, collectibleType, parent)
        end
    end
    collectible.Touched:Connect(onTouched)

    collectible.Parent = self.CollectibleContainer
    return collectible
end

-- Create power-up
function ObstacleService:CreatePowerUp(powerUpType, powerUpData, x, z)
    local powerUp = Instance.new("Part")
    powerUp.Name = powerUpData.name
    powerUp.Size = Vector3.new(2, 2, 2)
    powerUp.Material = Enum.Material.ForceField
    powerUp.BrickColor = BrickColor.new(powerUpData.color)
    powerUp.Anchored = true
    powerUp.CanCollide = false
    powerUp.Shape = Enum.PartType.Ball

    -- Position
    powerUp.Position = Vector3.new(x, 4, z)

    -- Add floating animation
    local floatTween = TweenService:Create(
        powerUp,
        TweenInfo.new(2, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1, true),
        { Position = Vector3.new(x, 5, z) }
    )
    floatTween:Play()

    -- Add collection detection
    local function onTouched(hit)
        local humanoid = hit.Parent:FindFirstChild("Humanoid")
        if humanoid then
            self:HandlePowerUpCollection(powerUp, powerUpType, humanoid.Parent)
        end
    end
    powerUp.Touched:Connect(onTouched)

    powerUp.Parent = self.CollectibleContainer
    return powerUp
end

-- Handle obstacle collision
function ObstacleService:HandleObstacleCollision(obstacle, obstacleType, character)
    -- Remove obstacle to prevent multiple collisions
    obstacle:Destroy()

    -- Remove from active obstacles
    for i, obstacleData in ipairs(self.ActiveObstacles) do
        if obstacleData.part == obstacle then
            table.remove(self.ActiveObstacles, i)
            break
        end
    end

    print("[ObstacleService] Player hit obstacle:", obstacleType)
end

-- Handle collectible collection
function ObstacleService:HandleCollectibleCollection(collectible, collectibleType, character)
    -- Remove collectible
    collectible:Destroy()

    -- Remove from active collectibles
    for i, collectibleData in ipairs(self.ActiveCollectibles) do
        if collectibleData.part == collectible then
            table.remove(self.ActiveCollectibles, i)
            break
        end
    end

    print("[ObstacleService] Player collected:", collectibleType)
end

-- Handle power-up collection
function ObstacleService:HandlePowerUpCollection(powerUp, powerUpType, character)
    -- Remove power-up
    powerUp:Destroy()

    -- Remove from active collectibles
    for i, collectibleData in ipairs(self.ActiveCollectibles) do
        if collectibleData.part == powerUp then
            table.remove(self.ActiveCollectibles, i)
            break
        end
    end

    print("[ObstacleService] Player collected power-up:", powerUpType)
end

-- Clean up distant obstacles and collectibles
function ObstacleService:CleanupDistantObstacles()
    local playerPosition = 0 -- This should be updated with actual player position

    -- Clean up obstacles
    for i = #self.ActiveObstacles, 1, -1 do
        local obstacleData = self.ActiveObstacles[i]
        if obstacleData.spawnZ < playerPosition - GameConfig.World.despawnDistance then
            obstacleData.part:Destroy()
            table.remove(self.ActiveObstacles, i)
        end
    end

    -- Clean up collectibles
    for i = #self.ActiveCollectibles, 1, -1 do
        local collectibleData = self.ActiveCollectibles[i]
        if collectibleData.spawnZ < playerPosition - GameConfig.World.despawnDistance then
            collectibleData.part:Destroy()
            table.remove(self.ActiveCollectibles, i)
        end
    end
end

-- Reset service
function ObstacleService:Reset()
    self:StopSpawning()

    -- Clear all obstacles
    for _, obstacleData in ipairs(self.ActiveObstacles) do
        obstacleData.part:Destroy()
    end
    self.ActiveObstacles = {}

    -- Clear all collectibles
    for _, collectibleData in ipairs(self.ActiveCollectibles) do
        collectibleData.part:Destroy()
    end
    self.ActiveCollectibles = {}

    -- Reset spawn position
    self.SpawnPosition = GameConfig.World.spawnDistance
end

return ObstacleService
