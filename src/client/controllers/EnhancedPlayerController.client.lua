-- Enhanced PlayerController mit echter Position Updates und Forward Movement
--!strict

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")

-- Sichere Module-Loading
local SharedFolder = ReplicatedStorage:WaitForChild("Shared", 10)
local GameConstants = if SharedFolder then require(SharedFolder:WaitForChild("GameConstants", 5)) else nil

-- Fallback für Game Constants
local function getLanePosition(lane: number): number
    if GameConstants and GameConstants.GetLanePosition then
        return GameConstants.GetLanePosition(lane)
    else
        -- Fallback zu eigener Lane-Berechnung
        return lane * 8 -- Standard lane width
    end
end

-- Enhanced PlayerController für echtes Subway Surfers Gameplay
local EnhancedPlayerController = {}
EnhancedPlayerController.__index = EnhancedPlayerController

-- Vollständige Typ Definitionen mit korrekten optional types
export type PlayerState = {
    lane: number,
    isJumping: boolean,
    isSliding: boolean,
    speed: number,
    distance: number,
    isGameActive: boolean,
}

-- EnhancedPlayerController Type mit allen Properties
type EnhancedPlayerControllerImpl = {
    player: Player,
    character: Model?,
    humanoid: Humanoid?,
    rootPart: BasePart?,
    state: PlayerState,
    forwardMovementConnection: RBXScriptConnection?,
    inputConnection: RBXScriptConnection?,
    movementTween: Tween?,

    -- Method signatures (self-referential)
    setupInputHandling: (EnhancedPlayerControllerImpl) -> (),
    startForwardMovement: (EnhancedPlayerControllerImpl) -> (),
    moveLeft: (EnhancedPlayerControllerImpl) -> (),
    moveRight: (EnhancedPlayerControllerImpl) -> (),
    animateToLane: (EnhancedPlayerControllerImpl) -> (),
    jump: (EnhancedPlayerControllerImpl) -> (),
    slide: (EnhancedPlayerControllerImpl) -> (),
    destroy: (EnhancedPlayerControllerImpl) -> (),
    pauseGame: (EnhancedPlayerControllerImpl) -> (),
    resumeGame: (EnhancedPlayerControllerImpl) -> (),
    resetGame: (EnhancedPlayerControllerImpl) -> (),
    initialize: (EnhancedPlayerControllerImpl) -> (),
    onCharacterAdded: (EnhancedPlayerControllerImpl, Model) -> (),
    sendPlayerAction: (EnhancedPlayerControllerImpl, string, any?) -> (),
    setupServerEvents: (EnhancedPlayerControllerImpl) -> (),
    handleGameStateChange: (EnhancedPlayerControllerImpl, string, any?) -> (),
    getDistance: (EnhancedPlayerControllerImpl) -> number,
    getSpeed: (EnhancedPlayerControllerImpl) -> number,
    getLane: (EnhancedPlayerControllerImpl) -> number,
    isActive: (EnhancedPlayerControllerImpl) -> boolean,
    setSpeed: (EnhancedPlayerControllerImpl, number) -> (),
    increaseSpeed: (EnhancedPlayerControllerImpl, number) -> (),
}

export type EnhancedPlayerController = EnhancedPlayerControllerImpl

-- Game Configuration
local CONFIG = {
    MOVEMENT_SPEED = 0.2, -- Lane switching speed
    FORWARD_SPEED = 25, -- Constant forward movement
    JUMP_HEIGHT = 20,
    JUMP_DURATION = 0.8,
    SLIDE_DURATION = 1.0,
    LANE_WIDTH = 8, -- Distance between lanes
}

function EnhancedPlayerController.new(): any
    local player = Players.LocalPlayer
    if not player then
        error("LocalPlayer not found")
    end

    local self = {
        player = player,
        character = nil :: Model?,
        humanoid = nil :: Humanoid?,
        rootPart = nil :: BasePart?,
        state = {
            lane = 0,
            isJumping = false,
            isSliding = false,
            speed = CONFIG.FORWARD_SPEED,
            distance = 0,
            isGameActive = true,
        } :: PlayerState,
        forwardMovementConnection = nil :: RBXScriptConnection?,
        inputConnection = nil :: RBXScriptConnection?,
        movementTween = nil :: Tween?,
    }
    setmetatable(self, EnhancedPlayerController)

    print("🎮 Enhanced PlayerController created - Subway Surfers ready!")
    return self
end

-- Bereinigung aller Verbindungen und Tweens
function EnhancedPlayerController:destroy()
    print("🧹 Bereinigung aller Verbindungen und Tweens")

    -- Stoppe alle aktiven Verbindungen - mit nil-checks
    local fmc = self.forwardMovementConnection
    if fmc then
        fmc:Disconnect()
        self.forwardMovementConnection = nil
    end

    local ic = self.inputConnection
    if ic then
        ic:Disconnect()
        self.inputConnection = nil
    end

    -- Stoppe alle aktiven Tweens - mit nil-checks
    local mt = self.movementTween
    if mt then
        mt:Cancel()
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

    self.forwardMovementConnection = RunService.Heartbeat:Connect(function(deltaTime: number)
        if not self.state.isGameActive or not self.rootPart then
            return
        end

        -- Type-safe calculations mit expliziten Annotations
        local speed: number = self.state.speed
        local currentDistance: number = self.state.distance
        local moveDistance: number = speed * deltaTime
        self.state.distance = currentDistance + moveDistance

        -- Bewege Character vorwärts (Z-Achse in Roblox)
        local currentCFrame: CFrame = self.rootPart.CFrame
        local newPosition: Vector3 = currentCFrame.Position + Vector3.new(0, 0, moveDistance)
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

-- Animiere zur Ziel-Lane mit GameConstants Integration
function EnhancedPlayerController:animateToLane()
    if not self.rootPart then
        return
    end

    -- Nutze getLanePosition für konsistente Lane-Positionen
    local targetX: number = getLanePosition(self.state.lane)
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
    local startY: number = self.rootPart.Position.Y
    local peakY: number = startY + CONFIG.JUMP_HEIGHT

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
    local originalSize: number = self.humanoid.HipHeight
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
    local currentSpeed: number = self.state.speed
    self.state.speed = currentSpeed + amount
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
    local success = pcall(function()
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
        warn("❌ Fehler bei Server-Kommunikation:", action)
    end
end

-- Game State Events Integration
function EnhancedPlayerController:setupServerEvents()
    local success = pcall(function()
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
        warn("❌ Fehler beim Setup der Server-Events")
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
    self.player.CharacterAdded:Connect(function(character: Model)
        self:onCharacterAdded(character)
    end)

    -- Handle Character mit nil-safe handling
    local currentCharacter = self.player.Character
    if currentCharacter then
        task.spawn(function()
            self:onCharacterAdded(currentCharacter)
        end)
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
