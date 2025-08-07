-- PlayerController.client.lua - Main client-side player movement and game control
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")

local player = Players.LocalPlayer

-- Wait for essential modules with proper error handling
local SubwaySurfersGameplay
local gameModulesReady = false

spawn(function()
	print("🔄 Waiting for game modules...")

	-- Load from correct Rojo path structure
	local success, result = pcall(function()
		-- Wait for Shared folder first
		local sharedFolder = ReplicatedStorage:WaitForChild("Shared", 30)
		if not sharedFolder then
			error("Shared folder not found in ReplicatedStorage")
		end

		-- Load SubwaySurfersGameplay module
		local gameplayModule = sharedFolder:WaitForChild("SubwaySurfersGameplay", 15)
		if not gameplayModule then
			error("SubwaySurfersGameplay module not found in Shared folder")
		end

		return require(gameplayModule)
	end)

	if success then
		SubwaySurfersGameplay = result
		print("✅ SubwaySurfersGameplay loaded successfully from ReplicatedStorage.Shared")
		gameModulesReady = true
		print("✅ All game modules loaded successfully")
	else
		warn("❌ Failed to load SubwaySurfersGameplay:", result)
		error("❌ Could not load SubwaySurfersGameplay: " .. tostring(result))
	end
end)

print("🎮 SUBWAY SURFERS PLAYER CONTROLLER ACTIVE")

-- Game state
local gameActive = false
local CURRENT_LANE = 0 -- Start in center lane (-1=left, 0=center, 1=right)
local MOVE_SPEED = 0.3 -- Lane switching speed
local START_COOLDOWN = 5.0 -- Increased cooldown between game starts
local lastStartTime = 0

-- Character references
local character = player.CharacterAdded:Wait()
local humanoid = character:WaitForChild("Humanoid")
local rootPart = character:WaitForChild("HumanoidRootPart")

-- Position player at starting position
local startPosition = Vector3.new(0, 5, 0) -- Center of track, slightly above ground
rootPart.CFrame = CFrame.lookAt(startPosition, startPosition + Vector3.new(0, 0, 100))

print("🎮 Player positioned at:", rootPart.Position.X, rootPart.Position.Y, rootPart.Position.Z)
print(
	"🎮 Player facing direction:",
	rootPart.CFrame.LookVector.X,
	rootPart.CFrame.LookVector.Y,
	rootPart.CFrame.LookVector.Z
)
print("🎮 Should be facing positive Z (forward toward track)")

-- Camera following setup
local camera = workspace.CurrentCamera
local cameraConnection
local CAMERA_OFFSET = Vector3.new(0, 8, -12) -- Behind and above player

local function startCameraFollow()
	if cameraConnection then
		cameraConnection:Disconnect()
	end

	camera.CameraType = Enum.CameraType.Scriptable

	cameraConnection = RunService.Heartbeat:Connect(function()
		if gameActive and character and rootPart then
			-- Camera follows behind player facing the same direction
			local cameraPosition = rootPart.Position + CAMERA_OFFSET
			camera.CFrame = CFrame.lookAt(cameraPosition, rootPart.Position + rootPart.CFrame.LookVector * 10)
		end
	end)

	print("🎥 Game camera setup complete - following player for correct orientation")
end

local function stopCameraFollow()
	if cameraConnection then
		cameraConnection:Disconnect()
		cameraConnection = nil
	end
	camera.CameraType = Enum.CameraType.Custom
	print("🎥 Camera following stopped")
end

-- Movement functions
local function switchLane(direction)
	if not gameActive then
		return
	end

	-- Calculate new lane
	local newLane = CURRENT_LANE + direction
	if newLane < -1 or newLane > 1 then
		return
	end -- Stay within bounds

	CURRENT_LANE = newLane

	-- Get target position
	local targetX = SubwaySurfersGameplay.GetLanePosition(CURRENT_LANE)
	local currentCFrame = rootPart.CFrame
	local targetCFrame = CFrame.new(
		Vector3.new(targetX, currentCFrame.Position.Y, currentCFrame.Position.Z),
		currentCFrame.Position + currentCFrame.LookVector
	)

	-- Smooth lane switching animation
	local moveInfo = TweenInfo.new(MOVE_SPEED, Enum.EasingStyle.Quad)
	local moveTween = TweenService:Create(rootPart, moveInfo, { CFrame = targetCFrame })
	moveTween:Play()

	print("🏃 LANE SWITCH to", CURRENT_LANE, "X:", targetX)
end

local function jump()
	if not gameActive then
		return
	end

	-- Simple jump - prevent multiple jumps
	if humanoid.FloorMaterial == Enum.Material.Air then
		return
	end -- Already jumping

	humanoid:ChangeState(Enum.HumanoidStateType.Jumping)
	print("🏃 JUMP!")
end

local function slide()
	if not gameActive then
		return
	end

	-- Ensure player is on ground for sliding
	if humanoid.FloorMaterial == Enum.Material.Air then
		return
	end

	-- Improved slide animation - crouch down for longer duration with collision detection
	local originalCFrame = rootPart.CFrame
	local slideCFrame = originalCFrame * CFrame.new(0, -2, 0)

	-- Create temporary slide hitbox (smaller than player)
	local slideHitbox = Instance.new("Part")
	slideHitbox.Name = "SlideHitbox"
	slideHitbox.Size = Vector3.new(2, 1, 2) -- Lower profile hitbox
	slideHitbox.Transparency = 1
	slideHitbox.CanCollide = false
	slideHitbox.Anchored = true
	slideHitbox.Parent = character
	slideHitbox.CFrame = rootPart.CFrame * CFrame.new(0, -1.5, 0)

	local slideInfo = TweenInfo.new(0.3, Enum.EasingStyle.Quad)
	local slideDown = TweenService:Create(rootPart, slideInfo, { CFrame = slideCFrame })
	local slideUp = TweenService:Create(rootPart, slideInfo, { CFrame = originalCFrame })

	slideDown:Play()
	slideDown.Completed:Connect(function()
		-- Update hitbox position during slide
		slideHitbox.CFrame = rootPart.CFrame * CFrame.new(0, -1.5, 0)

		task.wait(0.6) -- Stay in slide position
		slideUp:Play()
		slideUp.Completed:Connect(function()
			slideHitbox:Destroy() -- Clean up slide hitbox
		end)
	end)

	print("🏃 SLIDE!")
end

-- Updated server readiness check
local function isServerFullyReady()
	-- Check if modules are loaded
	if not gameModulesReady then
		warn("⚠️ Game modules not ready yet")
		return false
	end

	-- Check server ready signals
	local serverReady = ReplicatedStorage:FindFirstChild("ServerReady")
	local gameManagerReady = ReplicatedStorage:FindFirstChild("GameManagerReady")

	if not serverReady or not serverReady.Value then
		warn("⚠️ Server not ready")
		return false
	end

	if not gameManagerReady or not gameManagerReady.Value then
		warn("⚠️ GameManager not ready")
		return false
	end

	-- Check RemoteFunctions availability
	local RemoteFunctions = ReplicatedStorage:FindFirstChild("RemoteFunctions")
	if not RemoteFunctions then
		warn("⚠️ RemoteFunctions not available")
		return false
	end

	local GetServerStatus = RemoteFunctions:FindFirstChild("GetServerStatus")
	if not GetServerStatus then
		warn("⚠️ GetServerStatus function not available")
		return false
	end

	-- Try to call server status
	local success, status = pcall(function()
		return GetServerStatus:InvokeServer()
	end)

	if not success or not status or not status.ready then
		warn("⚠️ Server status check failed or server not ready")
		return false
	end

	return true
end

local startGame -- Forward declaration
startGame = function()
	print("[WorkingPlayerController] startGame() called")

	-- Wait for modules to be ready
	if not gameModulesReady then
		print("[WorkingPlayerController] Waiting for game modules...")
		while not gameModulesReady do
			task.wait(0.1)
		end
	end

	-- Debounce to prevent multiple rapid starts
	local currentTime = tick()
	if currentTime - lastStartTime < START_COOLDOWN then
		print("[WorkingPlayerController] Start game cooldown active, ignoring")
		return
	end
	lastStartTime = currentTime

	if gameActive then
		print("[WorkingPlayerController] Game already active, ignoring")
		return
	end -- Already active

	-- Comprehensive server readiness check
	if not isServerFullyReady() then
		warn("[WorkingPlayerController] Server not fully ready - deferring game start")
		task.wait(2.0)
		print("[WorkingPlayerController] Retrying game start after server check...")
		startGame()
		return
	end

	print("[WorkingPlayerController] Server confirmed fully ready - starting game...")
	gameActive = true

	-- Use SubwaySurfersGameplay safely
	if SubwaySurfersGameplay and SubwaySurfersGameplay.GetLanePosition then
		rootPart.CFrame = CFrame.lookAt(
			Vector3.new(SubwaySurfersGameplay.GetLanePosition(CURRENT_LANE), rootPart.Position.Y, rootPart.Position.Z),
			Vector3.new(
				SubwaySurfersGameplay.GetLanePosition(CURRENT_LANE),
				rootPart.Position.Y,
				rootPart.Position.Z + 100
			)
		)
		print(
			"🎯 Game started: Player locked to lane",
			CURRENT_LANE,
			"X position:",
			SubwaySurfersGameplay.GetLanePosition(CURRENT_LANE)
		)
	else
		warn("⚠️ SubwaySurfersGameplay not available, using fallback positioning")
		rootPart.CFrame = CFrame.lookAt(
			Vector3.new(0, rootPart.Position.Y, rootPart.Position.Z),
			Vector3.new(0, rootPart.Position.Y, rootPart.Position.Z + 100)
		)
	end

	-- Send start game action to server with error handling
	local success, err = pcall(function()
		local RemoteEvents = ReplicatedStorage:WaitForChild("RemoteEvents", 5)
		local PlayerActionEvent = RemoteEvents:WaitForChild("PlayerAction", 5)
		PlayerActionEvent:FireServer("StartGame", { timestamp = tick() })
	end)

	if success then
		print("[WorkingPlayerController] Sending StartGame action to server")
	else
		warn("[WorkingPlayerController] Failed to send StartGame action:", err)
	end

	print("🎮 GAME STARTED! Use WASD or Arrow Keys to move")

	-- Start camera following
	startCameraFollow()
end

local function stopGame()
	print("[WorkingPlayerController] stopGame() called")
	gameActive = false
	print("🛑 GAME STOPPED")

	-- Stop camera following
	stopCameraFollow()

	-- Send end game action to server
	local RemoteEvents = ReplicatedStorage:WaitForChild("RemoteEvents")
	if RemoteEvents then
		local PlayerActionEvent = RemoteEvents:WaitForChild("PlayerAction")
		if PlayerActionEvent then
			PlayerActionEvent:FireServer("EndGame", { timestamp = tick(), reason = "Manual stop" })
		end
	end

	-- Reset player position to starting position
	CURRENT_LANE = 0
	rootPart.CFrame = CFrame.lookAt(
		Vector3.new(SubwaySurfersGameplay.GetLanePosition(CURRENT_LANE), 5, 0),
		Vector3.new(SubwaySurfersGameplay.GetLanePosition(CURRENT_LANE), 5, 100)
	)
	print("🎯 Player reset to center lane facing forward")
end

-- Input handling
UserInputService.InputBegan:Connect(function(input, gameProcessed)
	if gameProcessed then
		return
	end

	-- Game control inputs (always available)
	if input.KeyCode == Enum.KeyCode.R then
		if gameActive then
			stopGame()
		else
			startGame()
		end
	end

	-- Movement inputs (only when game is active)
	if not gameActive then
		return
	end

	if input.KeyCode == Enum.KeyCode.A or input.KeyCode == Enum.KeyCode.Left then
		switchLane(-1) -- Move left
	elseif input.KeyCode == Enum.KeyCode.D or input.KeyCode == Enum.KeyCode.Right then
		switchLane(1) -- Move right
	elseif
		input.KeyCode == Enum.KeyCode.W
		or input.KeyCode == Enum.KeyCode.Up
		or input.KeyCode == Enum.KeyCode.Space
	then
		jump()
	elseif input.KeyCode == Enum.KeyCode.S or input.KeyCode == Enum.KeyCode.Down then
		slide()
	end
end)

-- Handle game state changes from server
local function onGameStateChanged(newState, data)
	print("[WorkingPlayerController] Server game state changed to:", newState)

	if newState == "Playing" then
		if not gameActive then
			gameActive = true
			startCameraFollow()
			print("[WorkingPlayerController] Server confirmed game started")
		end
	elseif newState == "Menu" then
		if gameActive then
			print("[WorkingPlayerController] Server says back to menu")
			stopGame()
		end
	elseif newState == "GameOver" then
		if gameActive then
			gameActive = false
			stopCameraFollow()
			print("[WorkingPlayerController] Game over - Final score:", data and data.finalScore or "Unknown")

			-- Auto restart after a delay
			task.wait(5) -- Increased delay
			print("[WorkingPlayerController] Auto-restarting game...")
			startGame()
		end
	end
end

-- Wait for server to be ready before starting game
local function waitForServerReady()
	print("🎮 WAITING FOR SERVER TO BE READY...")

	-- Wait for both server ready signals with longer timeout
	local serverReady = ReplicatedStorage:WaitForChild("ServerReady", 45) -- 45 second timeout
	if not serverReady then
		warn("🎮 ⚠️ Server ready signal not received - starting anyway")
		return
	end

	local gameManagerReady = ReplicatedStorage:WaitForChild("GameManagerReady", 15) -- 15 second timeout
	if not gameManagerReady then
		warn("🎮 ⚠️ GameManager ready signal not received - starting anyway")
	end

	-- Wait for both to be true
	local function checkBothReady()
		return serverReady.Value and (not gameManagerReady or gameManagerReady.Value)
	end

	if checkBothReady() then
		print("🎮 ✅ SERVER IS READY!")
		print("🎮 ⏳ Waiting for player initialization...")
		print("🎮 Auto-starting in 8 seconds to ensure proper initialization...")
		task.wait(8.0) -- Extended delay to ensure server has fully initialized player
		print("🎮 AUTO-STARTING SUBWAY SURFERS!")
		print("🎮 No need to press R - the game starts automatically!")
		startGame()
	else
		-- Server not ready yet, wait for value change
		print("🎮 ⏳ Server initializing... waiting for ready signal...")

		local function onReadyChanged()
			if checkBothReady() then
				print("🎮 ✅ SERVER IS NOW READY!")
				print("🎮 ⏳ Waiting for player initialization...")
				print("🎮 Auto-starting in 8 seconds to ensure proper initialization...")
				task.wait(8.0) -- Extended delay to ensure server has fully initialized player
				print("🎮 AUTO-STARTING SUBWAY SURFERS!")
				print("🎮 No need to press R - the game starts automatically!")
				startGame()
			end
		end

		serverReady.Changed:Connect(onReadyChanged)
		if gameManagerReady then
			gameManagerReady.Changed:Connect(onReadyChanged)
		end
	end
end

-- Connect to server events
task.spawn(function()
	local RemoteEvents = ReplicatedStorage:WaitForChild("RemoteEvents", 15) -- Increased timeout
	if RemoteEvents then
		local GameStateChangedEvent = RemoteEvents:WaitForChild("GameStateChanged", 10)
		if GameStateChangedEvent then
			GameStateChangedEvent.OnClientEvent:Connect(onGameStateChanged)
			print("🎮 Connected to server game state events")
		end

		local ScoreUpdateEvent = RemoteEvents:WaitForChild("ScoreUpdate", 10)
		if ScoreUpdateEvent then
			ScoreUpdateEvent.OnClientEvent:Connect(function(newScore, itemType)
				print("🎯 Score updated:", newScore, "from", itemType or "unknown")
			end)
		end
	end
end)

-- Handle character respawning
player.CharacterAdded:Connect(function(newCharacter)
	character = newCharacter
	humanoid = character:WaitForChild("Humanoid")
	rootPart = character:WaitForChild("HumanoidRootPart")

	-- Reset position and state
	task.wait(0.1) -- Wait for character to fully load
	rootPart.CFrame = CFrame.lookAt(Vector3.new(0, 5, 0), Vector3.new(0, 5, 100))

	gameActive = false
	CURRENT_LANE = 0

	print("🎮 Character respawned - ready for new game")
end)

-- Initialize
task.spawn(function()
	-- Give the server more time to initialize
	task.wait(5.0) -- Increased initial delay
	waitForServerReady()
end)

-- Status display
task.spawn(function()
	task.wait(8) -- Increased delay
	print("✅ SUBWAY SURFERS READY!")
	print("✅ Game will start automatically!")
	print("✅ Use WASD or Arrow Keys to move")
	print("✅ Space/W = Jump, S = Slide")
	print("✅ Collect yellow coins and blue power-ups")
	print("✅ Avoid red trains!")
	print("🎯 LANE SYSTEM: Left(-8), Center(0), Right(8)")
	print("🎯 LANES: A/Left = Move Left, D/Right = Move Right")
	print("🎯 ORIENTATION: Player faces positive Z, camera follows behind")
	print("🎥 CAMERA FIX: Movement should now match visual direction!")
end)
