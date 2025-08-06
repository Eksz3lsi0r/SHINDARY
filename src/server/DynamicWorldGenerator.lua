--!strict
-- DynamicWorldGenerator.lua - Enhanced Endless World Generation für Subway Surfers
-- Arbeitet zusammen mit SegmentSpawner für kohärente Welt-Generierung

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local workspace = game:GetService("Workspace")

-- Import shared systems (will be loaded when needed to avoid circular dependencies)
local _GameConfig = nil -- Loaded on demand
local _SegmentSpawner = nil -- Integration point

-- Enhanced DynamicWorldGenerator mit SegmentSpawner Integration
local DynamicWorldGenerator = {}
DynamicWorldGenerator.__index = DynamicWorldGenerator

-- Type Definitions für bessere Copilot-Unterstützung
export type SpawnableObject = {
    type: string,
    position: Vector3,
    lane: number,
    zPosition: number,
    instance: Instance?,
    metadata: { [string]: any }?,
}

export type GeneratorState = {
    isActive: boolean,
    playerPosition: Vector3,
    lastSpawnZ: number,
    spawnedObjects: { SpawnableObject },
    difficulty: number,
    mode: string, -- "DYNAMIC" or "SEGMENT_BASED"
}

export type DynamicWorldGenerator = {
    state: GeneratorState,
    updateConnection: RBXScriptConnection?,
    segmentSpawnerIntegration: boolean,
    new: () -> DynamicWorldGenerator,
    start: (self: DynamicWorldGenerator, initialPlayerPosition: Vector3) -> (),
    stop: (self: DynamicWorldGenerator) -> (),
    updatePlayerPosition: (self: DynamicWorldGenerator, newPosition: Vector3) -> (),
}

-- Enhanced Configuration
local CONFIG = {
    SPAWN_DISTANCE = 300, -- Erweiterte Spawn-Distanz
    DESPAWN_DISTANCE = 100, -- Cleanup-Distanz
    COIN_SPAWN_RATE = 0.6, -- Ausbalancierte Spawn-Rate
    OBSTACLE_SPAWN_RATE = 0.3, -- Faire Obstacle-Rate
    POWERUP_SPAWN_RATE = 0.08, -- Seltene Power-Ups
    SEGMENT_LENGTH = 25, -- Koordiniert mit SegmentSpawner
    LANE_POSITIONS = { -8, 0, 8 }, -- Standardisierte Lane-Positionen
    INTEGRATION_MODE = "ENHANCED", -- Erweiterte Integration
}

function DynamicWorldGenerator.new(): DynamicWorldGenerator
    local self: DynamicWorldGenerator = setmetatable({}, DynamicWorldGenerator)

    self.state = {
        isActive = false,
        playerPosition = Vector3.new(0, 0, 0),
        lastSpawnZ = 0,
        spawnedObjects = {},
        difficulty = 1,
        mode = "DYNAMIC", -- Neue Eigenschaft für Integrations-Modus
    }

    self.updateConnection = nil :: RBXScriptConnection?
    self.segmentSpawnerIntegration = false -- Integration Flag

    return self
end

-- Start dynamic world generation
function DynamicWorldGenerator:start(initialPlayerPosition: Vector3)
    if self.state.isActive then
        return
    end

    print("🌍 Starting Dynamic World Generation")
    self.state.isActive = true
    self.state.playerPosition = initialPlayerPosition
    self.state.lastSpawnZ = initialPlayerPosition.Z

    -- Clear existing spawned objects
    self:clearSpawnedObjects()

    -- Generate initial world ahead of player
    self:generateInitialWorld()

    -- Start update loop
    self:startUpdateLoop()
end

-- Stop world generation
function DynamicWorldGenerator:stop()
    if not self.state.isActive then
        return
    end

    print("🛑 Stopping Dynamic World Generation")
    self.state.isActive = false

    if self.updateConnection then
        self.updateConnection:Disconnect()
        self.updateConnection = nil
    end

    -- Clean up spawned objects
    self:clearSpawnedObjects()
end

-- Update player position (called from PlayerController)
function DynamicWorldGenerator:updatePlayerPosition(newPosition: Vector3)
    self.state.playerPosition = newPosition

    -- Update difficulty based on distance traveled
    self.state.difficulty = math.min(5, math.floor(newPosition.Z / 500) + 1)
end

-- Main update loop
function DynamicWorldGenerator:startUpdateLoop()
    if self.updateConnection then
        self.updateConnection:Disconnect()
    end

    self.updateConnection = RunService.Heartbeat:Connect(function()
        if not self.state.isActive then
            return
        end

        -- Generate new segments ahead of player
        self:generateAhead()

        -- Clean up objects behind player
        self:cleanupBehind()
    end)
end

-- Generate initial world segments
function DynamicWorldGenerator:generateInitialWorld()
    local startZ: number = self.state.playerPosition.Z

    -- Generate segments ahead
    for i = 1, 10 do
        local segmentZ: number = startZ + (i * CONFIG.SEGMENT_LENGTH)
        self:generateSegment(segmentZ)
    end

    print("🌍 Initial world generated")
end

-- Generate objects ahead of player
function DynamicWorldGenerator:generateAhead()
    local playerZ: number = self.state.playerPosition.Z
    local spawnZ: number = playerZ + CONFIG.SPAWN_DISTANCE

    -- Check if we need to spawn new segments
    if spawnZ > self.state.lastSpawnZ + CONFIG.SEGMENT_LENGTH then
        local segmentZ: number = self.state.lastSpawnZ + CONFIG.SEGMENT_LENGTH
        self:generateSegment(segmentZ)
        self.state.lastSpawnZ = segmentZ
    end
end

-- Generate a single track segment
function DynamicWorldGenerator:generateSegment(zPosition: number)
    print(`🌍 Generating segment at Z: {zPosition}`)

    -- Generate coins (multiple patterns)
    self:generateCoins(zPosition)

    -- Generate obstacles (ensure fair gameplay)
    self:generateObstacles(zPosition)

    -- Generate power-ups (rare but valuable)
    self:generatePowerUps(zPosition)
end

-- Generate coins for a segment
function DynamicWorldGenerator:generateCoins(zPosition: number)
    if math.random() > CONFIG.COIN_SPAWN_RATE then
        return
    end

    local patterns = {
        "line", -- Straight line of coins
        "zigzag", -- Zigzag pattern
        "cluster", -- Coins in all lanes
        "single", -- Single coin in random lane
    }

    local pattern = patterns[math.random(#patterns)]

    if pattern == "line" then
        -- Line of coins in one lane
        local lane = math.random(1, 3)
        local laneX = CONFIG.LANE_POSITIONS[lane]

        for i = 0, 4 do
            local coinZ = zPosition + (i * 4)
            self:spawnCoin(Vector3.new(laneX, 3, coinZ), lane - 2)
        end
    elseif pattern == "zigzag" then
        -- Zigzag pattern across lanes
        for i = 0, 2 do
            local lane = (i % 3) + 1
            local laneX = CONFIG.LANE_POSITIONS[lane]
            local coinZ = zPosition + (i * 6)
            self:spawnCoin(Vector3.new(laneX, 3, coinZ), lane - 2)
        end
    elseif pattern == "cluster" then
        -- Coins in all three lanes
        for lane = 1, 3 do
            local laneX = CONFIG.LANE_POSITIONS[lane]
            self:spawnCoin(Vector3.new(laneX, 3, zPosition), lane - 2)
        end
    elseif pattern == "single" then
        -- Single coin in random lane
        local lane = math.random(1, 3)
        local laneX = CONFIG.LANE_POSITIONS[lane]
        self:spawnCoin(Vector3.new(laneX, 3, zPosition), lane - 2)
    end
end

-- Generate obstacles for a segment
function DynamicWorldGenerator:generateObstacles(zPosition: number)
    if math.random() > CONFIG.OBSTACLE_SPAWN_RATE * self.state.difficulty then
        return
    end

    local obstacleTypes = {
        "TRAIN", -- Must jump over
        "BARRIER", -- Must slide under
        "WIDE_BARRIER", -- Blocks multiple lanes
    }

    local obstacleType = obstacleTypes[math.random(#obstacleTypes)]

    if obstacleType == "TRAIN" then
        -- Train in one lane - can be jumped over
        local lane = math.random(1, 3)
        local laneX = CONFIG.LANE_POSITIONS[lane]
        self:spawnObstacle("TRAIN", Vector3.new(laneX, 4, zPosition), lane - 2)
    elseif obstacleType == "BARRIER" then
        -- Low barrier - must slide under
        local lane = math.random(1, 3)
        local laneX = CONFIG.LANE_POSITIONS[lane]
        self:spawnObstacle("BARRIER", Vector3.new(laneX, 2, zPosition), lane - 2)
    elseif obstacleType == "WIDE_BARRIER" then
        -- Wide barrier blocking 2 lanes - must switch to safe lane
        local safeLane = math.random(1, 3)

        for lane = 1, 3 do
            if lane ~= safeLane then
                local laneX = CONFIG.LANE_POSITIONS[lane]
                self:spawnObstacle("WIDE_BARRIER", Vector3.new(laneX, 4, zPosition), lane - 2)
            end
        end
    end
end

-- Generate power-ups for a segment
function DynamicWorldGenerator:generatePowerUps(zPosition: number)
    if math.random() > CONFIG.POWERUP_SPAWN_RATE then
        return
    end

    local powerUpTypes = { "JETPACK", "MAGNET", "SHIELD", "SPEED_BOOST" }
    local powerUpType = powerUpTypes[math.random(#powerUpTypes)]

    -- Always spawn in center lane for visibility
    self:spawnPowerUp(powerUpType, Vector3.new(0, 4, zPosition), 0)
end

-- Spawn a coin object
function DynamicWorldGenerator:spawnCoin(position: Vector3, lane: number)
    local coin = Instance.new("Part")
    coin.Name = "Coin_" .. math.random(1000, 9999)
    coin.Size = Vector3.new(2, 2, 0.2)
    coin.Position = position
    coin.Material = Enum.Material.Neon
    coin.BrickColor = BrickColor.new("Bright yellow")
    coin.Shape = Enum.PartType.Cylinder
    coin.Anchored = true
    coin.CanCollide = false
    coin.Parent = workspace

    -- Add spinning animation
    local bodyAngularVelocity = Instance.new("BodyAngularVelocity")
    bodyAngularVelocity.AngularVelocity = Vector3.new(0, 10, 0)
    bodyAngularVelocity.MaxTorque = Vector3.new(0, math.huge, 0)
    bodyAngularVelocity.Parent = coin

    -- Add light effect
    local light = Instance.new("PointLight")
    light.Color = Color3.fromRGB(255, 215, 0)
    light.Brightness = 1
    light.Range = 8
    light.Parent = coin

    -- Track spawned object
    local spawnedObject: SpawnableObject = {
        type = "COIN",
        position = position,
        lane = lane,
        zPosition = position.Z,
        instance = coin,
    }

    table.insert(self.state.spawnedObjects, spawnedObject)

    print(`💰 Spawned coin at lane {lane}, Z: {position.Z}`)
end

-- Spawn an obstacle
function DynamicWorldGenerator:spawnObstacle(obstacleType: string, position: Vector3, lane: number)
    local obstacle = Instance.new("Part")
    obstacle.Name = obstacleType .. "_" .. math.random(1000, 9999)
    obstacle.Position = position
    obstacle.Material = Enum.Material.Concrete
    obstacle.BrickColor = BrickColor.new("Really red")
    obstacle.Anchored = true
    obstacle.CanCollide = false
    obstacle.Parent = workspace

    -- Configure based on type
    if obstacleType == "TRAIN" then
        obstacle.Size = Vector3.new(4, 6, 8)
        obstacle.BrickColor = BrickColor.new("Dark red")
    elseif obstacleType == "BARRIER" then
        obstacle.Size = Vector3.new(4, 3, 2)
        obstacle.BrickColor = BrickColor.new("Bright red")
    elseif obstacleType == "WIDE_BARRIER" then
        obstacle.Size = Vector3.new(4, 6, 4)
        obstacle.BrickColor = BrickColor.new("Really red")
    end

    -- Track spawned object
    local spawnedObject: SpawnableObject = {
        type = "OBSTACLE",
        position = position,
        lane = lane,
        zPosition = position.Z,
        instance = obstacle,
    }

    table.insert(self.state.spawnedObjects, spawnedObject)

    print(`🚧 Spawned {obstacleType} at lane {lane}, Z: {position.Z}`)
end

-- Spawn a power-up
function DynamicWorldGenerator:spawnPowerUp(powerUpType: string, position: Vector3, lane: number)
    local powerUp = Instance.new("Part")
    powerUp.Name = "PowerUp_" .. powerUpType .. "_" .. math.random(1000, 9999)
    powerUp.Size = Vector3.new(3, 3, 3)
    powerUp.Position = position
    powerUp.Material = Enum.Material.ForceField
    powerUp.BrickColor = BrickColor.new("Bright blue")
    powerUp.Shape = Enum.PartType.Block
    powerUp.Anchored = true
    powerUp.CanCollide = false
    powerUp.Parent = workspace

    -- Add floating animation
    local bodyPosition = Instance.new("BodyPosition")
    bodyPosition.MaxForce = Vector3.new(0, math.huge, 0)
    bodyPosition.Position = position
    bodyPosition.D = 500
    bodyPosition.P = 3000
    bodyPosition.Parent = powerUp

    -- Floating effect
    task.spawn(function()
        local startY = position.Y
        local time = 0

        while powerUp.Parent do
            time = time + 0.1
            bodyPosition.Position = Vector3.new(position.X, startY + math.sin(time) * 0.5, position.Z)
            task.wait(0.1)
        end
    end)

    -- Track spawned object
    local spawnedObject: SpawnableObject = {
        type = "POWERUP",
        position = position,
        lane = lane,
        zPosition = position.Z,
        instance = powerUp,
    }

    table.insert(self.state.spawnedObjects, spawnedObject)

    print(`⚡ Spawned {powerUpType} at lane {lane}, Z: {position.Z}`)
end

-- Clean up objects behind player
function DynamicWorldGenerator:cleanupBehind()
    local playerZ: number = self.state.playerPosition.Z
    local despawnZ: number = playerZ - CONFIG.DESPAWN_DISTANCE

    for i = #self.state.spawnedObjects, 1, -1 do
        local obj = self.state.spawnedObjects[i]

        if obj.zPosition < despawnZ then
            -- Remove from world
            if obj.instance and obj.instance.Parent then
                obj.instance:Destroy()
            end

            -- Remove from tracking
            table.remove(self.state.spawnedObjects, i)

            print(`🧹 Cleaned up {obj.type} at Z: {obj.zPosition}`)
        end
    end
end

-- Clear all spawned objects
function DynamicWorldGenerator:clearSpawnedObjects()
    for _, obj in ipairs(self.state.spawnedObjects) do
        if obj.instance and obj.instance.Parent then
            obj.instance:Destroy()
        end
    end

    self.state.spawnedObjects = {}
    print("🧹 All spawned objects cleared")
end

-- Get objects near position (for collision detection)
function DynamicWorldGenerator:getObjectsNear(position: Vector3, radius: number): { SpawnableObject }
    local nearbyObjects = {}

    for _, obj in ipairs(self.state.spawnedObjects) do
        if obj.instance and obj.instance.Parent then
            local distance: number = (obj.position - position).Magnitude
            if distance <= radius then
                table.insert(nearbyObjects, obj)
            end
        end
    end

    return nearbyObjects
end

-- Remove specific object (when collected)
function DynamicWorldGenerator:removeObject(objectToRemove: SpawnableObject)
    for i, obj in ipairs(self.state.spawnedObjects) do
        if obj == objectToRemove then
            if obj.instance and obj.instance.Parent then
                obj.instance:Destroy()
            end
            table.remove(self.state.spawnedObjects, i)
            break
        end
    end
end

-- Get current generator state
function DynamicWorldGenerator:getState(): GeneratorState
    return table.clone(self.state)
end

return DynamicWorldGenerator
