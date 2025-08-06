--!strict
-- CameraController.lua - Handle camera movement and effects for Subway Surfers
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local workspace = game:GetService("Workspace")

-- Typ-Definition für CameraController
export type CameraController = {
    Camera: Camera,
    Player: Player?,
    RootPart: BasePart?,
    CameraConnection: RBXScriptConnection?,
    OriginalCFrame: CFrame?,
    IsGameCameraActive: boolean,
    Initialize: (self: CameraController, player: Player, rootPart: BasePart) -> (),
    StartGameCamera: (self: CameraController) -> (),
    StopGameCamera: (self: CameraController) -> (),
    UpdateGameCamera: (self: CameraController) -> (),
    ReturnToMenu: (self: CameraController) -> (),
    ShakeCamera: (self: CameraController, intensity: number?) -> (),
    ApplyLaneTilt: (self: CameraController, direction: number) -> (),
    ApplySpeedEffect: (self: CameraController, isActive: boolean) -> (),
    SetFieldOfView: (self: CameraController, fov: number, duration: number?) -> Tween,
    Cleanup: (self: CameraController) -> (),
}

local CameraController = {} :: CameraController
CameraController.Camera = workspace.CurrentCamera
CameraController.Player = nil
CameraController.RootPart = nil
CameraController.CameraConnection = nil
CameraController.OriginalCFrame = nil
CameraController.IsGameCameraActive = false

-- Camera settings optimized for Subway Surfers
local CAMERA_OFFSET = Vector3.new(0, 8, -12) -- Behind and above player
local CAMERA_LOOK_AHEAD = 15 -- Look forward along track
local CAMERA_SMOOTHNESS = 0.15 -- Smooth following

-- Initialize camera controller
function CameraController:Initialize(player: Player, rootPart: BasePart)
    self.Player = player
    self.RootPart = rootPart
    self.OriginalCFrame = self.Camera.CFrame

    -- Set camera type to scriptable for full control
    self.Camera.CameraType = Enum.CameraType.Scriptable

    print("[CameraController] Camera initialized for Subway Surfers")
end

-- Start game camera following
function CameraController:StartGameCamera()
    if not self.RootPart then
        warn("[CameraController] No RootPart available")
        return
    end

    self.IsGameCameraActive = true

    -- Disconnect any existing connection
    if self.CameraConnection then
        self.CameraConnection:Disconnect()
    end

    -- Connect camera update to heartbeat for smooth following
    self.CameraConnection = RunService.Heartbeat:Connect(function()
        self:UpdateGameCamera()
    end)

    print("[CameraController] Game camera started - following player")

    -- Set initial camera position
    self:UpdateGameCamera()
end

-- Stop game camera
function CameraController:StopGameCamera()
    self.IsGameCameraActive = false

    if self.CameraConnection then
        self.CameraConnection:Disconnect()
    end
    self.CameraConnection = nil

    -- Return to default camera type
    self.Camera.CameraType = Enum.CameraType.Custom

    print("[CameraController] Game camera stopped")
end

-- Update camera position during gameplay - CRITICAL for proper orientation
function CameraController:UpdateGameCamera()
    if not self.RootPart or not self.IsGameCameraActive then
        return
    end

    local rootPosition: Vector3 = self.RootPart.Position
    local rootLookVector: Vector3 = self.RootPart.CFrame.LookVector

    -- Calculate camera position behind and above player
    local cameraPosition: Vector3 = rootPosition + CAMERA_OFFSET

    -- Look at position ahead of player along their facing direction
    local lookAtPosition: Vector3 = rootPosition + (rootLookVector * CAMERA_LOOK_AHEAD)

    -- Create target camera CFrame looking at the player's forward direction
    local targetCFrame = CFrame.lookAt(cameraPosition, lookAtPosition)

    -- Smooth camera movement
    self.Camera.CFrame = self.Camera.CFrame:Lerp(targetCFrame, CAMERA_SMOOTHNESS)
end

-- Return camera to menu position
function CameraController:ReturnToMenu()
    self:StopGameCamera()

    if self.OriginalCFrame then
        -- Smooth transition back to original position
        local tweenInfo = TweenInfo.new(1, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
        local tween = TweenService:Create(self.Camera, tweenInfo, { CFrame = self.OriginalCFrame })
        tween:Play()
    end

    print("[CameraController] Returned to menu camera")
end

-- Shake camera for collision effects
function CameraController:ShakeCamera(intensity: number?)
    if not self.IsGameCameraActive then
        return
    end

    local shakeIntensity: number = if intensity then intensity else 1
    local shakeAmount: number = 1.5 * shakeIntensity
    local shakeDuration: number = 0.3 * shakeIntensity

    -- Create shake effect
    local shakeStart = tick()

    local shakeConnection
    shakeConnection = RunService.Heartbeat:Connect(function()
        local elapsed = tick() - shakeStart
        if elapsed >= shakeDuration then
            shakeConnection:Disconnect()
            return
        end

        -- Calculate shake offset with decay
        local progress: number = elapsed / shakeDuration
        local shakeIntensity: number = (1 - progress) * shakeAmount

        local randomOffset: Vector3 = Vector3.new(
            (math.random() - 0.5) * shakeIntensity,
            (math.random() - 0.5) * shakeIntensity,
            0 -- Don't shake forward/backward
        )

        -- Apply shake to camera
        if self.IsGameCameraActive then
            self:UpdateGameCamera()
            self.Camera.CFrame = self.Camera.CFrame + randomOffset
        end
    end)
end

-- Lane switching camera tilt effect
function CameraController:ApplyLaneTilt(direction: number)
    if not self.IsGameCameraActive then
        return
    end

    -- Subtle camera roll when switching lanes (-1 = left, 1 = right)
    local tiltAmount = direction * 2 -- degrees

    -- Apply tilt effect
    spawn(function()
        local originalCFrame = self.Camera.CFrame
        local tiltedCFrame = originalCFrame * CFrame.Angles(0, 0, math.rad(tiltAmount))

        -- Quick tilt in
        local tweenInfo = TweenInfo.new(0.1, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
        local tiltTween = TweenService:Create(self.Camera, tweenInfo, { CFrame = tiltedCFrame })
        tiltTween:Play()

        -- Wait and tilt back
        tiltTween.Completed:Wait()
        task.wait(0.1)

        local returnTween = TweenService:Create(self.Camera, tweenInfo, { CFrame = originalCFrame })
        returnTween:Play()
    end)
end

-- Speed boost camera effect
function CameraController:ApplySpeedEffect(isActive)
    if isActive then
        -- Increase FOV for speed sensation
        self:SetFieldOfView(80, 0.3)
    else
        -- Return to normal FOV
        self:SetFieldOfView(70, 0.5)
    end
end

-- Set camera field of view
function CameraController:SetFieldOfView(fov: number, duration: number?): Tween
    local tweenDuration: number = if duration then duration else 0.5

    local tweenInfo = TweenInfo.new(tweenDuration, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
    local tween = TweenService:Create(self.Camera, tweenInfo, { FieldOfView = fov })
    tween:Play()

    return tween
end

-- Clean up camera controller
function CameraController:Cleanup()
    self:StopGameCamera()

    -- Reset camera to default
    self.Camera.CameraType = Enum.CameraType.Custom
    self.Camera.FieldOfView = 70

    if self.OriginalCFrame then
        self.Camera.CFrame = self.OriginalCFrame
    end

    print("[CameraController] Camera cleaned up")
end

return CameraController
