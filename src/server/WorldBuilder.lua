--!strict
-- WorldBuilder.lua - Unified World Management für Subway Surfers
-- Koordiniert zwischen statischer Basis-Welt und dynamischer Segment-Generierung
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

-- Import dependencies
local SubwaySurfersGameplay = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("SubwaySurfersGameplay"))

-- WorldBuilder - Master World Coordinator
local WorldBuilder = {}
WorldBuilder.__index = WorldBuilder

-- State Management
local isInitialized = false
local worldSystemInstance = nil

-- Initialize the game world - UNIFIED APPROACH
function WorldBuilder.Initialize()
    if isInitialized then
        print("[WorldBuilder] ⚠️ World system already initialized - using existing world")
        return true
    end

    print("[WorldBuilder] 🌍 Starting Unified World System...")

    -- Step 1: Check for existing world (avoid conflicts)
    if WorldBuilder:_checkExistingWorld() then
        print("[WorldBuilder] ✅ Found existing world - integrating with current system")
        isInitialized = true
        return true
    end

    -- Step 2: Create base world infrastructure
    local baseWorldSuccess = WorldBuilder:_createBaseWorld()
    if not baseWorldSuccess then
        warn("[WorldBuilder] ❌ Failed to create base world infrastructure")
        return false
    end

    -- Step 3: Initialize dynamic systems (will be used later)
    WorldBuilder:_prepareDynamicSystems()

    isInitialized = true
    print("[WorldBuilder] ✅ Unified World System initialized successfully!")
    return true
end

-- Check if any world already exists (from other scripts)
function WorldBuilder:_checkExistingWorld(): boolean
    local existingWorldElements = {
        "SubwayTrack",
        "MainTrack",
        "SpawnPlatform",
        "SubwayTrain_1",
        "Coin_1",
        "LaneMarker_L",
    }

    for _, elementName in ipairs(existingWorldElements) do
        if Workspace:FindFirstChild(elementName) then
            print("[WorldBuilder] 🔍 Found existing world element:", elementName)
            return true
        end
    end

    return false
end

-- Create base world infrastructure (static elements)
function WorldBuilder:_createBaseWorld(): boolean
    local success = pcall(function()
        -- Create main track platform
        WorldBuilder:CreateTrack()

        -- Create lane navigation markers
        WorldBuilder:CreateLaneMarkers()

        -- Create player spawn point
        WorldBuilder:CreateSpawnPoint()

        -- Setup atmospheric lighting
        WorldBuilder:SetupLighting()

        print("[WorldBuilder] 🏗️ Base world infrastructure created")
    end)

    return success
end

-- Prepare dynamic systems (but don't start them yet)
function WorldBuilder:_prepareDynamicSystems()
    -- This will be called by GameCoordinator when game starts
    print("[WorldBuilder] 🔧 Dynamic systems prepared for activation")

    -- Store reference for later use by other systems
    _G.WorldBuilder = WorldBuilder
end

-- Create the main track/platform
function WorldBuilder:CreateTrack()
    local track = Instance.new("Part")
    track.Name = "MainTrack"
    track.Size = Vector3.new(24, 2, 1000) -- Wide platform for 3 lanes
    track.Position = Vector3.new(0, -1, 500) -- Extended forward
    track.Material = Enum.Material.Concrete
    track.BrickColor = BrickColor.new("Dark stone grey")
    track.Anchored = true
    track.Parent = Workspace

    -- Add track texture/pattern
    local surface = Instance.new("SurfaceGui")
    surface.Parent = track
    surface.Face = Enum.NormalId.Top

    -- Create basic subway track lines
    for i = 1, 3 do
        local line = Instance.new("Frame")
        line.Size = UDim2.new(0.02, 0, 1, 0)
        line.Position = UDim2.new((i - 1) * 0.33 + 0.16, 0, 0, 0)
        line.BackgroundColor3 = Color3.fromRGB(255, 255, 0)
        line.BorderSizePixel = 0
        line.Parent = surface
    end
end

-- Create lane divider markers
function WorldBuilder:CreateLaneMarkers()
    local leftLaneX = SubwaySurfersGameplay.GetLanePosition(-1)
    local _centerLaneX = SubwaySurfersGameplay.GetLanePosition(0)
    local rightLaneX = SubwaySurfersGameplay.GetLanePosition(1)

    -- Create lane marker posts every 50 studs
    for z = 0, 1000, 50 do
        -- Left lane markerss
        local leftMarker = Instance.new("Part")
        leftMarker.Name = "LeftLaneMarker"
        leftMarker.Size = Vector3.new(0.5, 8, 0.5)
        leftMarker.Position = Vector3.new(leftLaneX - 4, 4, z)
        leftMarker.Material = Enum.Material.Neon
        leftMarker.BrickColor = BrickColor.new("Bright yellow")
        leftMarker.Anchored = true
        leftMarker.Parent = Workspace

        -- Right lane marker
        local rightMarker = Instance.new("Part")
        rightMarker.Name = "RightLaneMarker"
        rightMarker.Size = Vector3.new(0.5, 8, 0.5)
        rightMarker.Position = Vector3.new(rightLaneX + 4, 4, z)
        rightMarker.Material = Enum.Material.Neon
        rightMarker.BrickColor = BrickColor.new("Bright yellow")
        rightMarker.Anchored = true
        rightMarker.Parent = Workspace
    end
end

-- Create player spawn point
function WorldBuilder:CreateSpawnPoint()
    local spawnPoint = Instance.new("SpawnLocation")
    spawnPoint.Name = "PlayerSpawn"
    spawnPoint.Size = Vector3.new(4, 1, 4)
    spawnPoint.Position = Vector3.new(0, 2, 0)
    spawnPoint.Material = Enum.Material.Neon
    spawnPoint.BrickColor = BrickColor.new("Bright green")
    spawnPoint.TopSurface = Enum.SurfaceType.Smooth
    spawnPoint.Anchored = true
    spawnPoint.Parent = Workspace

    -- Add spawn effect
    local light = Instance.new("PointLight")
    light.Color = Color3.fromRGB(0, 255, 0)
    light.Brightness = 2
    light.Range = 10
    light.Parent = spawnPoint
end

-- Set up game lighting and atmosphere
function WorldBuilder:SetupLighting()
    local Lighting = game:GetService("Lighting")

    -- Set lighting properties for subway atmosphere
    Lighting.Brightness = 0.5
    Lighting.Ambient = Color3.fromRGB(100, 100, 120)
    Lighting.ColorShift_Bottom = Color3.fromRGB(50, 50, 80)
    Lighting.ColorShift_Top = Color3.fromRGB(150, 150, 200)
    Lighting.OutdoorAmbient = Color3.fromRGB(80, 80, 100)
    Lighting.TimeOfDay = "14:00:00" -- Afternoon lighting
    Lighting.FogEnd = 500
    Lighting.FogStart = 100
    Lighting.FogColor = Color3.fromRGB(100, 100, 120)

    -- Add atmosphere effects
    local Atmosphere = Instance.new("Atmosphere")
    Atmosphere.Density = 0.3
    Atmosphere.Offset = 0.25
    Atmosphere.Color = Color3.fromRGB(199, 199, 199)
    Atmosphere.Decay = Color3.fromRGB(106, 112, 125)
    Atmosphere.Glare = 0.4
    Atmosphere.Haze = 1.8
    Atmosphere.Parent = Lighting

    -- Add some tunnel lighting
    for z = 0, 1000, 100 do
        local streetLight = Instance.new("Part")
        streetLight.Name = "StreetLight"
        streetLight.Size = Vector3.new(1, 12, 1)
        streetLight.Position = Vector3.new(-15, 6, z)
        streetLight.Material = Enum.Material.Metal
        streetLight.BrickColor = BrickColor.new("Dark stone grey")
        streetLight.Anchored = true
        streetLight.Parent = Workspace

        local light = Instance.new("PointLight")
        light.Color = Color3.fromRGB(255, 220, 150)
        light.Brightness = 1.5
        light.Range = 20
        light.Parent = streetLight

        -- Create matching light on the other side
        local streetLight2 = streetLight:Clone()
        streetLight2.Position = Vector3.new(15, 6, z)
        streetLight2.Parent = Workspace
    end
end

-- Create basic obstacles for testing
function WorldBuilder:CreateTestObstacles()
    -- Create a few test obstacles
    local obstacles = {
        { type = "TRAIN", lane = 0, z = 100 },
        { type = "BARRIER", lane = -1, z = 150 },
        { type = "TUNNEL_ENTRANCE", lane = 1, z = 200 },
    }

    for _, obstacleData in ipairs(obstacles) do
        local obstacleType = SubwaySurfersGameplay.ObstacleTypes[obstacleData.type]
        if obstacleType then
            local obstacle = Instance.new("Part")
            obstacle.Name = obstacleType.name
            obstacle.Size = Vector3.new(obstacleType.width, obstacleType.height, 2)
            obstacle.Position = Vector3.new(
                SubwaySurfersGameplay.GetLanePosition(obstacleData.lane),
                obstacleType.height / 2,
                obstacleData.z
            )
            obstacle.Material = Enum.Material.Metal
            obstacle.BrickColor = BrickColor.new("Really red")
            obstacle.Anchored = true
            obstacle.Parent = Workspace
        end
    end
end

-- Create test collectibles
function WorldBuilder:CreateTestCollectibles()
    -- Create some test coins
    for i = 1, 20 do
        local coin = Instance.new("Part")
        coin.Name = "TestCoin"
        coin.Size = Vector3.new(1, 1, 0.2)
        coin.Position = Vector3.new(SubwaySurfersGameplay.GetLanePosition(math.random(-1, 1)), 3, i * 10 + 50)
        coin.Material = Enum.Material.Neon
        coin.BrickColor = BrickColor.new("Bright yellow")
        coin.Shape = Enum.PartType.Cylinder
        coin.Anchored = true
        coin.Parent = Workspace

        -- Add spinning animation
        local spin = Instance.new("BodyAngularVelocity")
        spin.AngularVelocity = Vector3.new(0, 10, 0)
        spin.MaxTorque = Vector3.new(0, math.huge, 0)
        spin.Parent = coin
    end
end

return WorldBuilder
