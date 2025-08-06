-- Enhanced PlayerController mit echter Position Updates und Forward Movement
--!strict

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")

-- Warte auf SubwaySurfersGameplay Module
local SharedFolder = ReplicatedStorage:WaitForChild("Shared")
local SubwaySurfersGameplay = require(SharedFolder:WaitForChild("SubwaySurfersGameplay"))

-- Enhanced PlayerController für echtes Subway Surfers Gameplay
local EnhancedPlayerController = {}
EnhancedPlayerController.__index = EnhancedPlayerController

-- Typ Definitionen
export type PlayerState = {
    lane: number,
    isJumping: boolean,
    isSliding: boolean,
    speed: number,
    distance: number,
    isGameActive: boolean,
}

export type EnhancedPlayerController = {
    player: Player,
    character: Model?,
    humanoid: Humanoid?,
    rootPart: BasePart?,
    state: PlayerState,
    forwardMovementConnection: RBXScriptConnection?,
    inputConnection: RBXScriptConnection?,
    movementTween: Tween?,
}

-- Game Configuration
local CONFIG = {
    MOVEMENT_SPEED = 0.2, -- Lane switching speed
    FORWARD_SPEED = 25, -- Constant forward movement
    JUMP_HEIGHT = 20,
    JUMP_DURATION = 0.8,
    SLIDE_DURATION = 1.0,
    LANE_WIDTH = 8, -- Distance between lanes
}

function EnhancedPlayerController.new(): EnhancedPlayerController
    local self = setmetatable({}, EnhancedPlayerController) :: EnhancedPlayerController

    -- Player References
    self.player = Players.LocalPlayer
    self.character = self.player.Character or self.player.CharacterAdded:Wait()
    self.humanoid = self.character:WaitForChild("Humanoid") :: Humanoid
    self.rootPart = self.character:WaitForChild("HumanoidRootPart") :: BasePart

    -- Game State
    self.state = {
        lane = 0, -- -1=left, 0=center, 1=right
        isJumping = false,
        isSliding = false,
        speed = CONFIG.FORWARD_SPEED,
        distance = 0,
        isGameActive = true,
    }

    -- Initialize connections as nil
    self.forwardMovementConnection = nil
    self.inputConnection = nil
    self.movementTween = nil

    -- Setup input handling
    self:setupInputHandling()

    -- Start forward movement
    self:startForwardMovement()

    print("🎮 Enhanced PlayerController initialisiert - Subway Surfers bereit!")
    return self
end

-- Bereinigung aller Verbindungen und Tweens
function EnhancedPlayerController:destroy()
    -- Stoppe alle aktiven Verbindungen
    if self.forwardMovementConnection then
        self.forwardMovementConnection:Disconnect()
        self.forwardMovementConnection = nil
    end

    if self.inputConnection then
        self.inputConnection:Disconnect()
        self.inputConnection = nil
    end

    -- Stoppe alle aktiven Tweens
    if self.movementTween then
        self.movementTween:Cancel()
        self.movementTween = nil
    end
end

-- Input Handling für Bewegungssteuerung
function EnhancedPlayerController:setupInputHandling()
    self.inputConnection = UserInputService.InputBegan:Connect(function(input, gameProcessed)
        if gameProcessed or not self.state.isGameActive then
            return
        end

        if input.KeyCode == Enum.KeyCode.A or input.KeyCode == Enum.KeyCode.Left then
            self:moveLeft()
        elseif input.KeyCode == Enum.KeyCode.D or input.KeyCode == Enum.KeyCode.Right then
            self:moveRight()
        elseif
            input.KeyCode == Enum.KeyCode.W
            or input.KeyCode == Enum.KeyCode.Up
            or input.KeyCode == Enum.KeyCode.Space
        then
            self:jump()
        elseif input.KeyCode == Enum.KeyCode.S or input.KeyCode == Enum.KeyCode.Down then
            self:slide()
        end
    end)
end

-- Konstante Vorwärtsbewegung
function EnhancedPlayerController:startForwardMovement()
    if not self.rootPart then
        return
    end

    self.forwardMovementConnection = RunService.Heartbeat:Connect(function(deltaTime)
        if not self.state.isGameActive or not self.rootPart then
            return
        end

        -- Aktualisiere Distanz
        local moveDistance = self.state.speed * deltaTime
        self.state.distance += moveDistance

        -- Bewege Character vorwärts (Z-Achse in Roblox)
        local currentCFrame = self.rootPart.CFrame
        local newPosition = currentCFrame.Position + Vector3.new(0, 0, moveDistance)
        self.rootPart.CFrame = CFrame.new(newPosition, newPosition + currentCFrame.LookVector)
    end)
end

-- Lane-basierte Bewegung (Links)
function EnhancedPlayerController:moveLeft()
    if self.state.lane > -1 then
        self.state.lane -= 1
        self:animateToLane()
    end
end

-- Lane-basierte Bewegung (Rechts)
function EnhancedPlayerController:moveRight()
    if self.state.lane < 1 then
        self.state.lane += 1
        self:animateToLane()
    end
end

-- Animiere zur Ziel-Lane mit SubwaySurfersGameplay Integration
function EnhancedPlayerController:animateToLane()
    if not self.rootPart then
        return
    end

    -- Nutze SubwaySurfersGameplay für konsistente Lane-Positionen
    local targetX = SubwaySurfersGameplay.GetLanePosition(self.state.lane)
    local currentCFrame = self.rootPart.CFrame

    -- Stoppe vorherige Bewegung
    if self.movementTween then
        self.movementTween:Cancel()
    end

    -- Erstelle neuen Tween für sanfte Bewegung
    local tweenInfo = TweenInfo.new(CONFIG.MOVEMENT_SPEED, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
    self.movementTween = TweenService:Create(self.rootPart, tweenInfo, {
        CFrame = CFrame.new(targetX, currentCFrame.Position.Y, currentCFrame.Position.Z),
    })

    self.movementTween:Play()
    print("🏃 Lane-Wechsel zu Lane", self.state.lane, "X-Position:", targetX)
end

-- Sprung-Mechanik
function EnhancedPlayerController:jump()
    if self.state.isJumping or self.state.isSliding then
        return
    end
    if not self.rootPart or not self.humanoid then
        return
    end

    self.state.isJumping = true

    -- Erstelle Sprung-Animation
    local startY = self.rootPart.Position.Y
    local peakY = startY + CONFIG.JUMP_HEIGHT

    -- Aufwärts-Bewegung
    local jumpUpTween = TweenService:Create(
        self.rootPart,
        TweenInfo.new(CONFIG.JUMP_DURATION / 2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
        { Position = Vector3.new(self.rootPart.Position.X, peakY, self.rootPart.Position.Z) }
    )

    -- Abwärts-Bewegung
    local jumpDownTween = TweenService:Create(
        self.rootPart,
        TweenInfo.new(CONFIG.JUMP_DURATION / 2, Enum.EasingStyle.Quad, Enum.EasingDirection.In),
        { Position = Vector3.new(self.rootPart.Position.X, startY, self.rootPart.Position.Z) }
    )

    -- Spiele Sprung-Sequenz ab
    jumpUpTween:Play()
    jumpUpTween.Completed:Connect(function()
        jumpDownTween:Play()
        jumpDownTween.Completed:Connect(function()
            self.state.isJumping = false
        end)
    end)
end

-- Rutsch-Mechanik
function EnhancedPlayerController:slide()
    if self.state.isJumping or self.state.isSliding then
        return
    end
    if not self.humanoid then
        return
    end

    self.state.isSliding = true

    -- Verändere Character-Größe für Rutsch-Effekt (verkleinerung der hitbox)
    local originalSize = self.humanoid.HipHeight
    self.humanoid.HipHeight = originalSize * 0.5

    -- Nach Slide-Duration zurücksetzen
    wait(CONFIG.SLIDE_DURATION)

    if self.humanoid then
        self.humanoid.HipHeight = originalSize
    end
    self.state.isSliding = false
end

-- Geschwindigkeits-Management
function EnhancedPlayerController:setSpeed(newSpeed: number)
    self.state.speed = math.max(0, newSpeed)
end

function EnhancedPlayerController:increaseSpeed(amount: number)
    self.state.speed += amount
end

-- Game State Management
function EnhancedPlayerController:pauseGame()
    self.state.isGameActive = false
end

function EnhancedPlayerController:resumeGame()
    self.state.isGameActive = true
end

function EnhancedPlayerController:resetGame()
    self.state.distance = 0
    self.state.speed = CONFIG.FORWARD_SPEED
    self.state.lane = 0
    self.state.isJumping = false
    self.state.isSliding = false
    self.state.isGameActive = true

    -- Resetze Position zur Mitte
    if self.rootPart then
        local currentPos = self.rootPart.Position
        self.rootPart.CFrame = CFrame.new(0, currentPos.Y, currentPos.Z)
    end
end

-- Getter für Game State
function EnhancedPlayerController:getDistance(): number
    return self.state.distance
end

function EnhancedPlayerController:getSpeed(): number
    return self.state.speed
end

function EnhancedPlayerController:getLane(): number
    return self.state.lane
end

function EnhancedPlayerController:isActive(): boolean
    return self.state.isGameActive
end

-- Character Event Handling
function EnhancedPlayerController:onCharacterAdded(character: Model)
    self.character = character
    self.humanoid = character:WaitForChild("Humanoid") :: Humanoid
    self.rootPart = character:WaitForChild("HumanoidRootPart") :: BasePart

    -- Restart forward movement mit neuem Character
    if self.forwardMovementConnection then
        self.forwardMovementConnection:Disconnect()
    end
    self:startForwardMovement()
end

-- Server Communication mit verbesserter Fehlerbehandlung
function EnhancedPlayerController:sendPlayerAction(action: string, data: any?)
    local success, result = pcall(function()
        local RemoteEvents = ReplicatedStorage:WaitForChild("RemoteEvents", 5)
        if not RemoteEvents then
            warn("⚠️ RemoteEvents nicht gefunden!")
            return
        end

        local PlayerActionEvent = RemoteEvents:WaitForChild("PlayerAction", 5)
        if PlayerActionEvent then
            PlayerActionEvent:FireServer(action, data)
            print("📤 PlayerAction gesendet:", action)
        end
    end)

    if not success then
        warn("❌ Fehler bei Server-Kommunikation:", action, result)
    end
end

-- Game State Events Integration
function EnhancedPlayerController:setupServerEvents()
    local success, result = pcall(function()
        local RemoteEvents = ReplicatedStorage:WaitForChild("RemoteEvents", 10)
        if not RemoteEvents then
            return
        end

        -- GameStateChanged Event
        local GameStateChangedEvent = RemoteEvents:WaitForChild("GameStateChanged", 5)
        if GameStateChangedEvent then
            GameStateChangedEvent.OnClientEvent:Connect(function(newState, data)
                self:handleGameStateChange(newState, data)
            end)
        end

        -- ScoreUpdate Event
        local ScoreUpdateEvent = RemoteEvents:WaitForChild("ScoreUpdate", 5)
        if ScoreUpdateEvent then
            ScoreUpdateEvent.OnClientEvent:Connect(function(newScore, itemType)
                print("🎯 Score Update:", newScore, "von", itemType or "unbekannt")
            end)
        end
    end)

    if not success then
        warn("❌ Fehler beim Setup der Server-Events:", result)
    end
end

-- Game State Change Handler
function EnhancedPlayerController:handleGameStateChange(newState: string, data: any?)
    print("🎮 Server Game State:", newState)

    if newState == "Playing" then
        if not self.state.isGameActive then
            self:resumeGame()
        end
    elseif newState == "Menu" then
        if self.state.isGameActive then
            self:pauseGame()
        end
    elseif newState == "GameOver" then
        self:pauseGame()
        print("💀 Game Over! Final Score:", data and data.finalScore or "Unbekannt")

        -- Auto-restart nach Delay
        task.wait(3)
        self:resetGame()
    end
end

-- Initialisiere PlayerController mit Server-Integration
function EnhancedPlayerController:initialize()
    -- Setup Character Change Detection
    self.player.CharacterAdded:Connect(function(character)
        self:onCharacterAdded(character)
    end)

    -- Handle Character
    if self.player.Character then
        self:onCharacterAdded(self.player.Character)
    end

    -- Setup Server Events
    self:setupServerEvents()

    print("✅ Enhanced PlayerController vollständig initialisiert!")
end

-- Auto-initialisierung
local playerController = EnhancedPlayerController.new()
playerController:initialize()

print("🎮 ENHANCED SUBWAY SURFERS CONTROLLER AKTIV!")
print("🎯 WASD/Pfeiltasten = Bewegung | Space/W = Sprung | S = Rutsch")

return EnhancedPlayerController
