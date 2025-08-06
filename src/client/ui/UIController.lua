--!nocheck
-- UIController.lua - Client-side UI management for Subway Surfers HUD
local UIController = {}

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")

local player = Players.LocalPlayer
if not player then
    error("LocalPlayer not found")
end
local playerGui = player:WaitForChild("PlayerGui")

-- Import shared modules
local GameConfig = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("GameConfig"))
local GameState = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("GameState"))

-- UI Elements (will be created dynamically)
local hudFrame: Frame
local scoreLabel: TextLabel
local coinsLabel: TextLabel
local distanceLabel: TextLabel
local speedLabel: TextLabel
local powerUpFrame: Frame
local pauseButton: TextButton
local _mobileControlsFrame: Frame

-- Legacy UI for compatibility
UIController.MenuUI = nil
UIController.GameUI = nil
UIController.EndGameUI = nil
UIController.CurrentUI = nil
UIController.PlayerController = nil

-- State
local currentScore = 0
local currentCoins = 0
local currentDistance = 0
local currentSpeed = 0
local activePowerUps: { [string]: number } = {} -- powerUpType -> endTime
local isGameActive = false
local isPaused = false

-- Remote Events
local RemoteEvents = ReplicatedStorage:WaitForChild("RemoteEvents")
local PlayerActionEvent = RemoteEvents:WaitForChild("PlayerAction")
local GameStateChangedEvent = RemoteEvents:WaitForChild("GameStateChanged")
local ScoreUpdateEvent = RemoteEvents:WaitForChild("ScoreUpdate")
local PowerUpActivatedEvent = RemoteEvents:WaitForChild("PowerUpActivated")
local PowerUpDeactivatedEvent = RemoteEvents:WaitForChild("PowerUpDeactivated")

-- Initialize UI controller
function UIController:Initialize(playerController)
    self.PlayerController = playerController

    -- Create UI elements
    self:CreateMenuUI()
    self:CreateGameUI()
    self:CreateEndGameUI()

    -- Show menu by default
    self:ShowMenuUI()

    print("[UIController] UI Controller initialized")
end

-- Create main menu UI
function UIController:CreateMenuUI()
    local screenGui = Instance.new("ScreenGui")
    screenGui.Name = "MenuUI"
    screenGui.ResetOnSpawn = false
    screenGui.Parent = playerGui

    -- Background
    local background = Instance.new("Frame")
    background.Name = "Background"
    background.Size = UDim2.fromScale(1, 1)
    background.BackgroundColor3 = Color3.fromRGB(25, 25, 25)
    background.BorderSizePixel = 0
    background.Parent = screenGui

    -- Title
    local title = Instance.new("TextLabel")
    title.Name = "Title"
    title.Size = UDim2.fromScale(0.8, 0.2)
    title.Position = UDim2.fromScale(0.1, 0.1)
    title.BackgroundTransparency = 1
    title.Text = "ENDLESS RUNNER"
    title.TextColor3 = Color3.fromRGB(255, 255, 255)
    title.TextScaled = true
    title.Font = Enum.Font.GothamBold
    title.Parent = background

    -- Play Button
    local playButton = Instance.new("TextButton")
    playButton.Name = "PlayButton"
    playButton.Size = UDim2.fromScale(0.3, 0.1)
    playButton.Position = UDim2.fromScale(0.35, 0.45)
    playButton.BackgroundColor3 = Color3.fromRGB(0, 170, 0)
    playButton.BorderSizePixel = 0
    playButton.Text = "PLAY"
    playButton.TextColor3 = Color3.fromRGB(255, 255, 255)
    playButton.TextScaled = true
    playButton.Font = Enum.Font.GothamBold
    playButton.Parent = background

    -- Play button functionality
    playButton.MouseButton1Click:Connect(function()
        self.PlayerController:SendAction("StartGame")
    end)

    -- Stats Display
    local statsFrame = Instance.new("Frame")
    statsFrame.Name = "StatsFrame"
    statsFrame.Size = UDim2.fromScale(0.4, 0.3)
    statsFrame.Position = UDim2.fromScale(0.3, 0.6)
    statsFrame.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
    statsFrame.BorderSizePixel = 0
    statsFrame.Parent = background

    local statsTitle = Instance.new("TextLabel")
    statsTitle.Name = "StatsTitle"
    statsTitle.Size = UDim2.fromScale(1, 0.3)
    statsTitle.Position = UDim2.fromScale(0, 0)
    statsTitle.BackgroundTransparency = 1
    statsTitle.Text = "YOUR STATS"
    statsTitle.TextColor3 = Color3.fromRGB(255, 255, 255)
    statsTitle.TextScaled = true
    statsTitle.Font = Enum.Font.Gotham
    statsTitle.Parent = statsFrame

    local highScoreLabel = Instance.new("TextLabel")
    highScoreLabel.Name = "HighScoreLabel"
    highScoreLabel.Size = UDim2.fromScale(1, 0.2)
    highScoreLabel.Position = UDim2.fromScale(0, 0.3)
    highScoreLabel.BackgroundTransparency = 1
    highScoreLabel.Text = "High Score: 0"
    highScoreLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
    highScoreLabel.TextScaled = true
    highScoreLabel.Font = Enum.Font.Gotham
    highScoreLabel.Parent = statsFrame

    local coinsLabel = Instance.new("TextLabel")
    coinsLabel.Name = "CoinsLabel"
    coinsLabel.Size = UDim2.fromScale(1, 0.2)
    coinsLabel.Position = UDim2.fromScale(0, 0.5)
    coinsLabel.BackgroundTransparency = 1
    coinsLabel.Text = "Coins: 0"
    coinsLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
    coinsLabel.TextScaled = true
    coinsLabel.Font = Enum.Font.Gotham
    coinsLabel.Parent = statsFrame

    local gamesPlayedLabel = Instance.new("TextLabel")
    gamesPlayedLabel.Name = "GamesPlayedLabel"
    gamesPlayedLabel.Size = UDim2.fromScale(1, 0.2)
    gamesPlayedLabel.Position = UDim2.fromScale(0, 0.7)
    gamesPlayedLabel.BackgroundTransparency = 1
    gamesPlayedLabel.Text = "Games Played: 0"
    gamesPlayedLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
    gamesPlayedLabel.TextScaled = true
    gamesPlayedLabel.Font = Enum.Font.Gotham
    gamesPlayedLabel.Parent = statsFrame

    self.MenuUI = screenGui
end

-- Create game UI
function UIController:CreateGameUI()
    local screenGui = Instance.new("ScreenGui")
    screenGui.Name = "GameUI"
    screenGui.ResetOnSpawn = false
    screenGui.Enabled = false
    screenGui.Parent = playerGui

    -- Score Display
    local scoreFrame = Instance.new("Frame")
    scoreFrame.Name = "ScoreFrame"
    scoreFrame.Size = UDim2.fromScale(0.3, 0.1)
    scoreFrame.Position = UDim2.fromScale(0.05, 0.05)
    scoreFrame.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
    scoreFrame.BackgroundTransparency = 0.5
    scoreFrame.BorderSizePixel = 0
    scoreFrame.Parent = screenGui

    local scoreLabel = Instance.new("TextLabel")
    scoreLabel.Name = "ScoreLabel"
    scoreLabel.Size = UDim2.fromScale(1, 1)
    scoreLabel.Position = UDim2.fromScale(0, 0)
    scoreLabel.BackgroundTransparency = 1
    scoreLabel.Text = "Score: 0"
    scoreLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
    scoreLabel.TextScaled = true
    scoreLabel.Font = Enum.Font.GothamBold
    scoreLabel.Parent = scoreFrame

    -- Distance Display
    local distanceFrame = Instance.new("Frame")
    distanceFrame.Name = "DistanceFrame"
    distanceFrame.Size = UDim2.fromScale(0.3, 0.1)
    distanceFrame.Position = UDim2.fromScale(0.65, 0.05)
    distanceFrame.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
    distanceFrame.BackgroundTransparency = 0.5
    distanceFrame.BorderSizePixel = 0
    distanceFrame.Parent = screenGui

    local distanceLabel = Instance.new("TextLabel")
    distanceLabel.Name = "DistanceLabel"
    distanceLabel.Size = UDim2.fromScale(1, 1)
    distanceLabel.Position = UDim2.fromScale(0, 0)
    distanceLabel.BackgroundTransparency = 1
    distanceLabel.Text = "Distance: 0m"
    distanceLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
    distanceLabel.TextScaled = true
    distanceLabel.Font = Enum.Font.GothamBold
    distanceLabel.Parent = distanceFrame

    -- Pause Button
    local pauseButton = Instance.new("TextButton")
    pauseButton.Name = "PauseButton"
    pauseButton.Size = UDim2.fromScale(0.1, 0.1)
    pauseButton.Position = UDim2.fromScale(0.45, 0.05)
    pauseButton.BackgroundColor3 = Color3.fromRGB(100, 100, 100)
    pauseButton.BorderSizePixel = 0
    pauseButton.Text = "||"
    pauseButton.TextColor3 = Color3.fromRGB(255, 255, 255)
    pauseButton.TextScaled = true
    pauseButton.Font = Enum.Font.GothamBold
    pauseButton.Parent = screenGui

    pauseButton.MouseButton1Click:Connect(function()
        self.PlayerController:SendAction("PauseGame")
    end)

    self.GameUI = screenGui
end

-- Create end game UI
function UIController:CreateEndGameUI()
    local screenGui = Instance.new("ScreenGui")
    screenGui.Name = "EndGameUI"
    screenGui.ResetOnSpawn = false
    screenGui.Enabled = false
    screenGui.Parent = playerGui

    -- Background
    local background = Instance.new("Frame")
    background.Name = "Background"
    background.Size = UDim2.fromScale(1, 1)
    background.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
    background.BackgroundTransparency = 0.3
    background.BorderSizePixel = 0
    background.Parent = screenGui

    -- Results Panel
    local resultsPanel = Instance.new("Frame")
    resultsPanel.Name = "ResultsPanel"
    resultsPanel.Size = UDim2.fromScale(0.6, 0.7)
    resultsPanel.Position = UDim2.fromScale(0.2, 0.15)
    resultsPanel.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
    resultsPanel.BorderSizePixel = 0
    resultsPanel.Parent = background

    -- Game Over Title
    local gameOverTitle = Instance.new("TextLabel")
    gameOverTitle.Name = "GameOverTitle"
    gameOverTitle.Size = UDim2.fromScale(1, 0.2)
    gameOverTitle.Position = UDim2.fromScale(0, 0)
    gameOverTitle.BackgroundTransparency = 1
    gameOverTitle.Text = "GAME OVER"
    gameOverTitle.TextColor3 = Color3.fromRGB(255, 100, 100)
    gameOverTitle.TextScaled = true
    gameOverTitle.Font = Enum.Font.GothamBold
    gameOverTitle.Parent = resultsPanel

    -- Final Score
    local finalScoreLabel = Instance.new("TextLabel")
    finalScoreLabel.Name = "FinalScoreLabel"
    finalScoreLabel.Size = UDim2.fromScale(1, 0.15)
    finalScoreLabel.Position = UDim2.fromScale(0, 0.25)
    finalScoreLabel.BackgroundTransparency = 1
    finalScoreLabel.Text = "Final Score: 0"
    finalScoreLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
    finalScoreLabel.TextScaled = true
    finalScoreLabel.Font = Enum.Font.Gotham
    finalScoreLabel.Parent = resultsPanel

    -- Play Again Button
    local playAgainButton = Instance.new("TextButton")
    playAgainButton.Name = "PlayAgainButton"
    playAgainButton.Size = UDim2.fromScale(0.4, 0.12)
    playAgainButton.Position = UDim2.fromScale(0.1, 0.75)
    playAgainButton.BackgroundColor3 = Color3.fromRGB(0, 170, 0)
    playAgainButton.BorderSizePixel = 0
    playAgainButton.Text = "PLAY AGAIN"
    playAgainButton.TextColor3 = Color3.fromRGB(255, 255, 255)
    playAgainButton.TextScaled = true
    playAgainButton.Font = Enum.Font.GothamBold
    playAgainButton.Parent = resultsPanel

    playAgainButton.MouseButton1Click:Connect(function()
        self.PlayerController:SendAction("StartGame")
    end)

    -- Menu Button
    local menuButton = Instance.new("TextButton")
    menuButton.Name = "MenuButton"
    menuButton.Size = UDim2.fromScale(0.4, 0.12)
    menuButton.Position = UDim2.fromScale(0.5, 0.75)
    menuButton.BackgroundColor3 = Color3.fromRGB(100, 100, 100)
    menuButton.BorderSizePixel = 0
    menuButton.Text = "MENU"
    menuButton.TextColor3 = Color3.fromRGB(255, 255, 255)
    menuButton.TextScaled = true
    menuButton.Font = Enum.Font.GothamBold
    menuButton.Parent = resultsPanel

    menuButton.MouseButton1Click:Connect(function()
        self:ShowMenuUI()
    end)

    self.EndGameUI = screenGui
end

-- Show menu UI
function UIController:ShowMenuUI(menuData)
    self:HideAllUI()
    if self.MenuUI then
        self.MenuUI.Enabled = true
        self.CurrentUI = self.MenuUI

        -- Update stats if data provided
        if menuData then
            self:UpdateMenuStats(menuData)
        end
    end
end

-- Show game UI
function UIController:ShowGameUI()
    self:HideAllUI()
    if self.GameUI then
        self.GameUI.Enabled = true
        self.CurrentUI = self.GameUI
    end
end

-- Show end game UI
function UIController:ShowEndGameUI(endData)
    self:HideAllUI()
    if self.EndGameUI then
        self.EndGameUI.Enabled = true
        self.CurrentUI = self.EndGameUI

        -- Update final score
        if endData and endData.finalScore then
            local finalScoreLabel = self.EndGameUI.Background.ResultsPanel.FinalScoreLabel
            finalScoreLabel.Text = "Final Score: " .. endData.finalScore
        end
    end
end

-- Hide all UI
function UIController:HideAllUI()
    if self.MenuUI then
        self.MenuUI.Enabled = false
    end
    if self.GameUI then
        self.GameUI.Enabled = false
    end
    if self.EndGameUI then
        self.EndGameUI.Enabled = false
    end
    self.CurrentUI = nil
end

-- Update game state
function UIController:UpdateGameState(gameState, data)
    -- Handle UI transitions based on game state
    if gameState == GameState.States.MENU then
        self:ShowMenuUI(data)
    elseif gameState == GameState.States.PLAYING then
        self:ShowGameUI()
    elseif gameState == GameState.States.GAME_OVER then
        self:ShowEndGameUI(data)
    end
end

-- Update score display
function UIController:UpdateScore(totalScore, scoreGained)
    if self.GameUI and self.GameUI.Enabled then
        local scoreLabel = self.GameUI.ScoreFrame.ScoreLabel
        scoreLabel.Text = "Score: " .. totalScore

        -- Animate score gain if provided
        if scoreGained and scoreGained > 0 then
            self:AnimateScoreGain(scoreGained)
        end
    end
end

-- Animate score gain effect
function UIController:AnimateScoreGain(scoreGained)
    -- Create floating score text
    local floatingScore = Instance.new("TextLabel")
    floatingScore.Size = UDim2.fromScale(0.2, 0.1)
    floatingScore.Position = UDim2.fromScale(0.4, 0.3)
    floatingScore.BackgroundTransparency = 1
    floatingScore.Text = "+" .. scoreGained
    floatingScore.TextColor3 = Color3.fromRGB(255, 255, 0)
    floatingScore.TextScaled = true
    floatingScore.Font = Enum.Font.GothamBold
    floatingScore.Parent = self.GameUI

    -- Animate floating effect
    local tweenInfo = TweenInfo.new(1, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
    local tween = TweenService:Create(floatingScore, tweenInfo, {
        Position = UDim2.fromScale(0.4, 0.1),
        TextTransparency = 1,
    })
    tween:Play()

    -- Clean up after animation
    tween.Completed:Connect(function()
        floatingScore:Destroy()
    end)
end

-- Update menu stats
function UIController:UpdateMenuStats(playerData)
    if not self.MenuUI or not playerData then
        return
    end

    local statsFrame = self.MenuUI.Background.StatsFrame
    statsFrame.HighScoreLabel.Text = "High Score: " .. (playerData.highScore or 0)
    statsFrame.CoinsLabel.Text = "Coins: " .. (playerData.coins or 0)
    statsFrame.GamesPlayedLabel.Text = "Games Played: " .. (playerData.gamesPlayed or 0)
end

-- Show collectible effect
function UIController:ShowCollectibleEffect(collectibleType, value)
    -- Visual feedback for collecting items
    -- This could include particle effects, sound, etc.
    print("[UIController] Collected:", collectibleType, "Value:", value)
end

-- Show damage effect
function UIController:ShowDamageEffect()
    -- Visual feedback for taking damage
    if not self.GameUI then
        return
    end

    -- Flash red overlay
    local damageOverlay = Instance.new("Frame")
    damageOverlay.Size = UDim2.fromScale(1, 1)
    damageOverlay.Position = UDim2.fromScale(0, 0)
    damageOverlay.BackgroundColor3 = Color3.fromRGB(255, 0, 0)
    damageOverlay.BackgroundTransparency = 0.7
    damageOverlay.BorderSizePixel = 0
    damageOverlay.Parent = self.GameUI

    -- Fade out
    local tweenInfo = TweenInfo.new(0.5, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
    local tween = TweenService:Create(damageOverlay, tweenInfo, { BackgroundTransparency = 1 })
    tween:Play()

    tween.Completed:Connect(function()
        damageOverlay:Destroy()
    end)
end

return UIController
