--!strict
-- SegmentSpawner.lua - Unified Track Segment Generation (Integrated with WorldBuilder)
-- Arbeitet zusammen mit DynamicWorldGenerator für kohärente Welt-Erstellung

local SegmentSpawner = {}

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

-- Enhanced module loading mit Fehlerbehandlung
local function loadModuleSafe(path: string, fallback: any?): any?
    local success, module = pcall(function()
        return require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild(path))
    end)

    if success and module then
        return module
    else
        warn("[SegmentSpawner] Failed to load module:", path)
        return fallback or {}
    end
end

-- Import shared modules mit safe loading
local GameConfig = loadModuleSafe("GameConfig") :: any
local SubwaySurfersGameplay = loadModuleSafe("SubwaySurfersGameplay") :: any

-- Enhanced Type Definitions
export type SegmentData = {
    id: string,
    position: Vector3,
    length: number,
    obstacles: { any },
    collectibles: { any },
    pattern: string,
    difficulty: number,
    isActive: boolean,
    spawnTime: number,
}

-- Enhanced Constants
local SEGMENT_LENGTH = 50
local SEGMENTS_AHEAD = 3 -- Reduziert um Konflikte zu vermeiden
local SPAWN_DISTANCE = 150 -- Reduziert für bessere Performance
local DESPAWN_DISTANCE = -50

-- State Management
local activeSegments: { SegmentData } = {}
local segmentCounter = 0
local isInitialized = false
local integrationMode = false -- Kooperation mit DynamicWorldGenerator

-- Enhanced Segment Templates mit besserer Balance
local segmentTemplates = {
    {
        name = "BasicRun",
        length = SEGMENT_LENGTH,
        difficulty = 1,
        obstacles = { "BARRIER" },
        collectibles = { "COIN_LINE" },
        spawnChance = 0.5,
    },
    {
        name = "CoinCollection",
        length = SEGMENT_LENGTH,
        difficulty = 1,
        obstacles = {},
        collectibles = { "COIN_LINE", "COIN" },
        spawnChance = 0.3,
    },
    {
        name = "PowerUpRun",
        length = SEGMENT_LENGTH,
        difficulty = 2,
        obstacles = { "SIGN_POST" },
        collectibles = { "COIN", "POWER_UP" },
        spawnChance = 0.15,
        hasPowerUp = true,
    },
}

-- Initialize the segment spawner
function SegmentSpawner:Initialize()
    if isInitialized then
        print("[SegmentSpawner] ⚠️ Already initialized, skipping duplicate initialization")
        return
    end

    print("[SegmentSpawner] Initializing segment spawning system...")

    -- Create initial segments
    self:SpawnInitialSegments()

    -- Connect to update loop
    RunService.Heartbeat:Connect(function()
        self:Update()
    end)

    isInitialized = true
    print("[SegmentSpawner] ✅ Segment spawning system initialized successfully")
end

-- Spawn initial segments
function SegmentSpawner:SpawnInitialSegments()
    print("[SegmentSpawner] Creating initial track segments...")

    -- Create starting platform
    self:CreateStartingPlatform()

    -- Create initial segments ahead
    for i = 1, SEGMENTS_AHEAD do
        local zPosition = i * SEGMENT_LENGTH
        self:CreateSegment(zPosition, "BasicRun", 1)
    end

    print("[SegmentSpawner] Initial segments created")
end

-- Create starting platform (safe spawn area)
function SegmentSpawner:CreateStartingPlatform()
    local startPlatform = Instance.new("Part")
    startPlatform.Name = "StartingPlatform"
    startPlatform.Size = Vector3.new(20, 2, 30)
    startPlatform.Position = Vector3.new(0, 0, -15)
    startPlatform.Material = Enum.Material.Concrete
    startPlatform.BrickColor = BrickColor.new("Medium stone grey")
    startPlatform.Anchored = true
    startPlatform.Parent = workspace

    -- Add lane markers
    for lane = -1, 1 do
        local marker = Instance.new("Part")
        marker.Name = "LaneMarker_" .. lane
        marker.Size = Vector3.new(0.2, 0.1, 30)
        marker.Position = Vector3.new(SubwaySurfersGameplay.GetLanePosition(lane), 1.1, -15)
        marker.Material = Enum.Material.Neon
        marker.BrickColor = BrickColor.new("Bright yellow")
        marker.Anchored = true
        marker.Parent = startPlatform
    end

    print("[SegmentSpawner] Starting platform created")
end

-- Create a new segment
function SegmentSpawner:CreateSegment(zPosition: number, templateName: string?, difficulty: number?)
    segmentCounter = segmentCounter + 1

    -- Select template
    local template = self:SelectTemplate(templateName, difficulty or 1)
    if not template then
        warn("[SegmentSpawner] Failed to find segment template:", templateName)
        return
    end

    -- Create segment data
    local segmentData: SegmentData = {
        id = "Segment_" .. segmentCounter,
        position = Vector3.new(0, 0, zPosition),
        length = template.length,
        obstacles = {},
        collectibles = {},
        pattern = template.name,
        difficulty = template.difficulty,
        isActive = true,
        spawnTime = tick(),
    }

    -- Create base platform
    local _platform = self:CreateBasePlatform(segmentData)

    -- Add obstacles
    self:SpawnObstacles(segmentData, template.obstacles)

    -- Add collectibles
    self:SpawnCollectibles(segmentData, template.collectibles, template.hasPowerUp)

    -- Add to active segments
    table.insert(activeSegments, segmentData)

    print("[SegmentSpawner] Created segment:", segmentData.id, "at Z:", zPosition)
    return segmentData
end

-- Select appropriate template based on difficulty and randomness
function SegmentSpawner:SelectTemplate(templateName: string?, difficulty: number): any?
    if templateName then
        for _, template in ipairs(segmentTemplates) do
            if template.name == templateName then
                return template
            end
        end
    end

    -- Random selection based on spawn chance and difficulty
    local availableTemplates = {}
    for _, template in ipairs(segmentTemplates) do
        if template.difficulty <= difficulty and math.random() < template.spawnChance then
            table.insert(availableTemplates, template)
        end
    end

    if #availableTemplates > 0 then
        return availableTemplates[math.random(1, #availableTemplates)]
    end

    -- Fallback to basic run
    return segmentTemplates[1]
end

-- Create base platform for segment
function SegmentSpawner:CreateBasePlatform(segmentData: SegmentData): Part
    local platform = Instance.new("Part")
    platform.Name = segmentData.id .. "_Platform"
    platform.Size = Vector3.new(GameConfig.World.platformWidth, GameConfig.World.platformHeight, segmentData.length)
    platform.Position = segmentData.position
    platform.Material = Enum.Material.Concrete
    platform.BrickColor = BrickColor.new("Medium stone grey")
    platform.Anchored = true
    platform.Parent = workspace

    -- Add lane dividers
    for lane = -1, 1 do
        if lane ~= 0 then -- Don't put divider in center
            local divider = Instance.new("Part")
            divider.Name = "LaneDivider_" .. lane
            divider.Size = Vector3.new(0.1, 0.2, segmentData.length)
            divider.Position = Vector3.new(
                SubwaySurfersGameplay.GetLanePosition(lane) + (lane < 0 and 4 or -4),
                segmentData.position.Y + 1.1,
                segmentData.position.Z
            )
            divider.Material = Enum.Material.Neon
            divider.BrickColor = BrickColor.new("Bright yellow")
            divider.Anchored = true
            divider.Parent = platform
        end
    end

    return platform
end

-- Spawn obstacles in segment
function SegmentSpawner:SpawnObstacles(segmentData: SegmentData, obstacleTypes: { string })
    local obstacleCount = math.random(1, 3)
    local usedLanes = {}

    for _ = 1, obstacleCount do
        local obstacleType = obstacleTypes[math.random(1, #obstacleTypes)]
        local availableLanes = {}

        -- Find available lanes
        for lane = -1, 1 do
            if not usedLanes[lane] then
                table.insert(availableLanes, lane)
            end
        end

        if #availableLanes == 0 then
            break -- No more lanes available
        end

        local lane = availableLanes[math.random(1, #availableLanes)]
        usedLanes[lane] = true

        local obstacle = self:CreateObstacle(obstacleType, lane, segmentData)
        if obstacle then
            table.insert(segmentData.obstacles, obstacle)
        end
    end
end

-- Create individual obstacle
function SegmentSpawner:CreateObstacle(obstacleType: string, lane: number, segmentData: SegmentData): Part?
    local obstacleData = SubwaySurfersGameplay.ObstacleTypes[obstacleType]
    if not obstacleData then
        warn("[SegmentSpawner] Unknown obstacle type:", obstacleType)
        return nil
    end

    local obstacle = Instance.new("Part")
    obstacle.Name = obstacleType .. "_" .. segmentData.id
    obstacle.Size = Vector3.new(obstacleData.width, obstacleData.height, 2)
    obstacle.Position = Vector3.new(
        SubwaySurfersGameplay.GetLanePosition(lane),
        segmentData.position.Y + obstacleData.height / 2 + 1,
        segmentData.position.Z + math.random(-segmentData.length / 3, segmentData.length / 3)
    )
    obstacle.Material = Enum.Material.Metal
    obstacle.BrickColor = BrickColor.new("Really red")
    obstacle.Anchored = true
    obstacle.Parent = workspace

    -- Add obstacle type data
    local stringValue = Instance.new("StringValue")
    stringValue.Name = "ObstacleType"
    stringValue.Value = obstacleType
    stringValue.Parent = obstacle

    return obstacle
end

-- Spawn collectibles in segment
function SegmentSpawner:SpawnCollectibles(segmentData: SegmentData, collectibleTypes: { string }, hasPowerUp: boolean?)
    -- Spawn regular collectibles
    for _, collectibleType in ipairs(collectibleTypes) do
        if collectibleType == "COIN_LINE" then
            self:CreateCoinLine(segmentData)
        elseif collectibleType == "COIN" then
            self:CreateScatteredCoins(segmentData, math.random(3, 8))
        elseif collectibleType == "GEM" then
            self:CreateGem(segmentData)
        elseif collectibleType == "MYSTERY_BOX" then
            self:CreateMysteryBox(segmentData)
        end
    end

    -- Spawn power-up if specified
    if hasPowerUp then
        self:CreatePowerUp(segmentData)
    end
end

-- Create coin line (like Subway Surfers)
function SegmentSpawner:CreateCoinLine(segmentData: SegmentData)
    local lane = math.random(-1, 1)
    local coinCount = 8
    local spacing = segmentData.length / (coinCount + 1)

    for i = 1, coinCount do
        local coin = self:CreateCoin(
            Vector3.new(
                SubwaySurfersGameplay.GetLanePosition(lane),
                segmentData.position.Y + 3,
                segmentData.position.Z - segmentData.length / 2 + (i * spacing)
            )
        )
        if coin then
            table.insert(segmentData.collectibles, coin)
        end
    end
end

-- Create scattered coins
function SegmentSpawner:CreateScatteredCoins(segmentData: SegmentData, count: number)
    for _ = 1, count do
        local lane = math.random(-1, 1)
        local coin = self:CreateCoin(
            Vector3.new(
                SubwaySurfersGameplay.GetLanePosition(lane),
                segmentData.position.Y + 3,
                segmentData.position.Z + math.random(-segmentData.length / 2, segmentData.length / 2)
            )
        )
        if coin then
            table.insert(segmentData.collectibles, coin)
        end
    end
end

-- Create individual coin
function SegmentSpawner:CreateCoin(position: Vector3): Part?
    local coin = Instance.new("Part")
    coin.Name = "Coin"
    coin.Shape = Enum.PartType.Cylinder
    coin.Size = Vector3.new(0.2, 2, 2)
    coin.Position = position
    coin.Material = Enum.Material.Neon
    coin.BrickColor = BrickColor.new("Bright yellow")
    coin.Anchored = true
    coin.CanCollide = false
    coin.Parent = workspace

    -- Add rotation animation
    local rotateConnection
    rotateConnection = RunService.Heartbeat:Connect(function(deltaTime)
        if coin.Parent then
            coin.CFrame = coin.CFrame * CFrame.Angles(0, 0, math.rad(360 * deltaTime * 2))
        else
            rotateConnection:Disconnect()
        end
    end)

    return coin
end

-- Create power-up
function SegmentSpawner:CreatePowerUp(segmentData: SegmentData)
    local lane = math.random(-1, 1)
    local powerUp = Instance.new("Part")
    powerUp.Name = "PowerUp"
    powerUp.Shape = Enum.PartType.Block
    powerUp.Size = Vector3.new(2, 2, 2)
    powerUp.Position =
        Vector3.new(SubwaySurfersGameplay.GetLanePosition(lane), segmentData.position.Y + 3, segmentData.position.Z)
    powerUp.Material = Enum.Material.ForceField
    powerUp.BrickColor = BrickColor.new("Bright blue")
    powerUp.Anchored = true
    powerUp.CanCollide = false
    powerUp.Parent = workspace

    -- Add pulsing effect
    local pulseConnection
    pulseConnection = RunService.Heartbeat:Connect(function()
        if powerUp.Parent then
            local time = tick()
            local scale = 1 + 0.2 * math.sin(time * 4)
            powerUp.Size = Vector3.new(2 * scale, 2 * scale, 2 * scale)
        else
            pulseConnection:Disconnect()
        end
    end)

    table.insert(segmentData.collectibles, powerUp)
end

-- Create gem
function SegmentSpawner:CreateGem(segmentData: SegmentData)
    local lane = math.random(-1, 1)
    local gem = Instance.new("Part")
    gem.Name = "Gem"
    gem.Shape = Enum.PartType.Ball
    gem.Size = Vector3.new(1.5, 1.5, 1.5)
    gem.Position = Vector3.new(
        SubwaySurfersGameplay.GetLanePosition(lane),
        segmentData.position.Y + 3,
        segmentData.position.Z + math.random(-segmentData.length / 3, segmentData.length / 3)
    )
    gem.Material = Enum.Material.Neon
    gem.BrickColor = BrickColor.new("Bright green")
    gem.Anchored = true
    gem.CanCollide = false
    gem.Parent = workspace

    table.insert(segmentData.collectibles, gem)
end

-- Create mystery box
function SegmentSpawner:CreateMysteryBox(segmentData: SegmentData)
    local lane = math.random(-1, 1)
    local box = Instance.new("Part")
    box.Name = "MysteryBox"
    box.Shape = Enum.PartType.Block
    box.Size = Vector3.new(2, 2, 2)
    box.Position =
        Vector3.new(SubwaySurfersGameplay.GetLanePosition(lane), segmentData.position.Y + 3, segmentData.position.Z)
    box.Material = Enum.Material.Neon
    box.BrickColor = BrickColor.new("Bright violet")
    box.Anchored = true
    box.CanCollide = false
    box.Parent = workspace

    table.insert(segmentData.collectibles, box)
end

-- Update loop - manage segment spawning and cleanup
function SegmentSpawner:Update()
    -- Get player position (safe player access)
    local Players = game:GetService("Players")
    local player = Players:GetPlayers()[1]
    if not player or not player.Character or not player.Character:FindFirstChild("HumanoidRootPart") then
        return
    end

    local playerZ = (player.Character:FindFirstChild("HumanoidRootPart") :: BasePart).Position.Z

    -- Check if we need to spawn new segments ahead
    local furthestZ = self:GetFurthestSegmentZ()
    if playerZ + SPAWN_DISTANCE > furthestZ then
        local newZ = furthestZ + SEGMENT_LENGTH
        local difficulty = math.min(5, math.floor(playerZ / 500) + 1)
        self:CreateSegment(newZ, nil, difficulty)
    end

    -- Clean up old segments behind player
    self:CleanupOldSegments(playerZ)
end

-- Get Z position of furthest segment
function SegmentSpawner:GetFurthestSegmentZ(): number
    local furthestZ = 0
    for _, segment in ipairs(activeSegments) do
        local segmentEndZ = segment.position.Z + segment.length / 2
        if segmentEndZ > furthestZ then
            furthestZ = segmentEndZ
        end
    end
    return furthestZ
end

-- Clean up segments that are behind the player
function SegmentSpawner:CleanupOldSegments(playerZ: number)
    local segmentsToRemove = {}

    for i, segment in ipairs(activeSegments) do
        local segmentEndZ = segment.position.Z + segment.length / 2
        if segmentEndZ < playerZ + DESPAWN_DISTANCE then
            table.insert(segmentsToRemove, i)

            -- Clean up segment parts
            self:DestroySegment(segment)
        end
    end

    -- Remove from active list (reverse order to maintain indices)
    for i = #segmentsToRemove, 1, -1 do
        table.remove(activeSegments, segmentsToRemove[i])
    end

    if #segmentsToRemove > 0 then
        print("[SegmentSpawner] Cleaned up", #segmentsToRemove, "old segments")
    end
end

-- Destroy segment and all its parts
function SegmentSpawner:DestroySegment(segment: SegmentData)
    -- Find and destroy platform
    local platform = workspace:FindFirstChild(segment.id .. "_Platform")
    if platform then
        platform:Destroy()
    end

    -- Destroy obstacles
    for _, obstacle in ipairs(segment.obstacles) do
        if obstacle and obstacle.Parent then
            obstacle:Destroy()
        end
    end

    -- Destroy collectibles
    for _, collectible in ipairs(segment.collectibles) do
        if collectible and collectible.Parent then
            collectible:Destroy()
        end
    end
end

-- Get active segments (for debugging)
function SegmentSpawner:GetActiveSegments(): { SegmentData }
    return activeSegments
end

-- Reset spawner (for game restart)
function SegmentSpawner:Reset()
    print("[SegmentSpawner] Resetting segment spawner...")

    -- Clean up all active segments
    for _, segment in ipairs(activeSegments) do
        self:DestroySegment(segment)
    end

    activeSegments = {}
    segmentCounter = 0

    -- Respawn initial segments
    self:SpawnInitialSegments()

    print("[SegmentSpawner] Segment spawner reset complete")
end

return SegmentSpawner
