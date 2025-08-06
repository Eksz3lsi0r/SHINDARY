--!strict
-- EffectsController.lua - Visual effects system for Subway Surfers
local Debris = game:GetService("Debris")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local _ReplicatedStorage = game:GetService("ReplicatedStorage")

-- Note: ObjectPool will be loaded when needed to avoid circular dependency

local EffectsController = {}

-- Type definitions
type Effect = {
    part: BasePart,
    tween: Tween?,
    connection: RBXScriptConnection?,
    startTime: number,
    duration: number,
}

type EffectConfig = {
    size: Vector3,
    color: Color3,
    material: Enum.Material,
    duration: number,
    scaleMultiplier: number?,
    count: number?,
}

-- Active effects tracking
local activeEffects: { Effect } = {}

-- Effect configurations
local EFFECT_CONFIGS: { [string]: EffectConfig } = {
    coin_collect = {
        size = Vector3.new(2, 2, 0.1),
        color = Color3.fromRGB(255, 215, 0),
        material = Enum.Material.Neon,
        duration = 1.5,
        scaleMultiplier = 3,
    },
    gem_collect = {
        size = Vector3.new(1.5, 1.5, 0.1),
        color = Color3.fromRGB(138, 43, 226),
        material = Enum.Material.ForceField,
        duration = 2,
        scaleMultiplier = 4,
    },
    power_up = {
        size = Vector3.new(3, 3, 0.1),
        color = Color3.fromRGB(0, 255, 255),
        material = Enum.Material.Neon,
        duration = 2.5,
        scaleMultiplier = 5,
    },
    speed_lines = {
        size = Vector3.new(0.5, 0.5, 15),
        color = Color3.fromRGB(255, 255, 255),
        material = Enum.Material.Neon,
        duration = 0.3,
        count = 8,
    },
    explosion = {
        size = Vector3.new(5, 5, 5),
        color = Color3.fromRGB(255, 100, 0),
        material = Enum.Material.Neon,
        duration = 1,
        scaleMultiplier = 3,
    },
}

-- Initialize effects controller
function EffectsController:Initialize()
    -- Cleanup loop for active effects
    RunService.Heartbeat:Connect(function()
        self:UpdateActiveEffects()
    end)

    print("[EffectsController] Visual effects system initialized")
end

-- Create a new effect part
function EffectsController:CreateEffectPart(effectName: string, config: EffectConfig): BasePart
    local part = Instance.new("Part")
    part.Name = effectName .. "_effect"
    part.Size = config.size
    part.Color = config.color
    part.Material = config.material
    part.Anchored = true
    part.CanCollide = false
    part.TopSurface = Enum.SurfaceType.Smooth
    part.BottomSurface = Enum.SurfaceType.Smooth

    return part
end

-- Play collectible collection effect
function EffectsController:PlayCollectibleEffect(position: Vector3, collectibleType: string)
    local effectType = "coin_collect"
    if collectibleType == "GEM" then
        effectType = "gem_collect"
    elseif collectibleType == "KEY" or collectibleType == "MYSTERY_BOX" then
        effectType = "power_up"
    end

    local config = EFFECT_CONFIGS[effectType]
    if not config then
        return
    end

    local effectPart = self:CreateEffectPart(effectType, config)

    -- Position the effect
    effectPart.CFrame = CFrame.new(position)
    effectPart.Parent = workspace

    -- Create collection animation
    local scaleMultiplier = config.scaleMultiplier or 2
    local targetSize = effectPart.Size * scaleMultiplier
    local endPosition = position + Vector3.new(0, 10, 0)

    -- Scale and fade animation
    local tweenInfo = TweenInfo.new(config.duration, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)

    local scaleTween = TweenService:Create(effectPart, tweenInfo, {
        Size = targetSize,
        Transparency = 1,
        CFrame = CFrame.new(endPosition),
    })

    scaleTween:Play()

    -- Store effect for cleanup
    local effect: Effect = {
        part = effectPart,
        tween = scaleTween,
        connection = nil,
        startTime = tick(),
        duration = config.duration,
    }

    table.insert(activeEffects, effect)

    -- Cleanup when done
    scaleTween.Completed:Connect(function()
        effectPart:Destroy()
        self:RemoveActiveEffect(effect)
    end)
end

-- Play speed boost effect
function EffectsController:PlaySpeedEffect(rootPart: BasePart, isActive: boolean)
    if not rootPart then
        return
    end

    if isActive then
        -- Create speed lines effect
        local config = EFFECT_CONFIGS.speed_lines

        for i = 1, config.count do
            local speedLine = Instance.new("Part")
            speedLine.Name = "SpeedLine"
            speedLine.Size = config.size
            speedLine.Color = config.color
            speedLine.Material = config.material
            speedLine.Anchored = true
            speedLine.CanCollide = false
            speedLine.Transparency = 0.5

            -- Random position around player
            local angle = (i / config.count) * math.pi * 2
            local radius = 8
            local offset = Vector3.new(math.cos(angle) * radius, math.random(-2, 2), math.sin(angle) * radius)

            speedLine.CFrame = rootPart.CFrame + offset
            speedLine.Parent = workspace

            -- Animate speed lines
            local targetPosition = speedLine.Position - Vector3.new(0, 0, 30)
            local tweenInfo = TweenInfo.new(config.duration, Enum.EasingStyle.Linear)
            local moveTween = TweenService:Create(speedLine, tweenInfo, {
                CFrame = CFrame.new(targetPosition),
                Transparency = 1,
            })

            moveTween:Play()

            -- Cleanup
            Debris:AddItem(speedLine, config.duration + 0.1)
        end
    end
end

-- Play power-up activation effect
function EffectsController:PlayPowerUpEffect(position: Vector3, powerUpType: string)
    local config = EFFECT_CONFIGS.power_up

    -- Create power-up effect part
    local effectPart = self:CreateEffectPart("power_up", config)

    -- Set power-up specific color
    if powerUpType == "JETPACK" then
        effectPart.Color = Color3.fromRGB(255, 140, 0)
    elseif powerUpType == "SUPER_SNEAKERS" then
        effectPart.Color = Color3.fromRGB(0, 255, 0)
    elseif powerUpType == "COIN_MAGNET" then
        effectPart.Color = Color3.fromRGB(255, 0, 255)
    elseif powerUpType == "MULTIPLIER" then
        effectPart.Color = Color3.fromRGB(255, 255, 0)
    end

    effectPart.CFrame = CFrame.new(position)
    effectPart.Parent = workspace

    -- Pulsing effect
    local tweenInfo = TweenInfo.new(
        config.duration / 4,
        Enum.EasingStyle.Sine,
        Enum.EasingDirection.InOut,
        3, -- Repeat 3 times
        true -- Reverse
    )

    local pulseTween = TweenService:Create(effectPart, tweenInfo, {
        Size = effectPart.Size * 1.5,
        Transparency = 0.3,
    })

    pulseTween:Play()

    -- Final fade out
    pulseTween.Completed:Connect(function()
        local fadeInfo = TweenInfo.new(0.5, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
        local fadeTween = TweenService:Create(effectPart, fadeInfo, {
            Transparency = 1,
            Size = effectPart.Size * 0.1,
        })
        fadeTween:Play()

        -- Cleanup
        Debris:AddItem(effectPart, 0.6)
    end)
end

-- Play obstacle hit effect
function EffectsController:PlayObstacleHitEffect(position: Vector3)
    local effect = "explosion"
    local config = EFFECT_CONFIGS[effect]

    -- Create explosion effect
    local explosion = Instance.new("Part")
    explosion.Name = "ExplosionEffect"
    explosion.Size = config.size
    explosion.Color = config.color
    explosion.Material = config.material
    explosion.Anchored = true
    explosion.CanCollide = false
    explosion.Shape = Enum.PartType.Ball
    explosion.CFrame = CFrame.new(position)
    explosion.Transparency = 0.3
    explosion.Parent = workspace

    -- Explosion animation
    local tweenInfo = TweenInfo.new(config.duration, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
    local explosionTween = TweenService:Create(explosion, tweenInfo, {
        Size = config.size * config.scaleMultiplier,
        Transparency = 1,
    })

    explosionTween:Play()

    -- Cleanup
    Debris:AddItem(explosion, config.duration + 0.1)
end

-- Play coin magnet effect
function EffectsController:PlayCoinMagnetEffect(playerPosition: Vector3, coinPosition: Vector3)
    -- Create magnetic trail
    local trail = Instance.new("Part")
    trail.Name = "MagnetTrail"
    trail.Size = Vector3.new(0.2, 0.2, (playerPosition - coinPosition).Magnitude)
    trail.Color = Color3.fromRGB(255, 0, 255)
    trail.Material = Enum.Material.Neon
    trail.Anchored = true
    trail.CanCollide = false
    trail.Transparency = 0.5

    -- Position trail between player and coin
    local midPoint = (playerPosition + coinPosition) / 2
    trail.CFrame = CFrame.lookAt(midPoint, coinPosition)
    trail.Parent = workspace

    -- Animated trail
    local tweenInfo = TweenInfo.new(0.3, Enum.EasingStyle.Sine, Enum.EasingDirection.Out)
    local trailTween = TweenService:Create(trail, tweenInfo, {
        Size = Vector3.new(0.5, 0.5, trail.Size.Z),
        Transparency = 1,
    })

    trailTween:Play()

    -- Cleanup
    Debris:AddItem(trail, 0.4)
end

-- Update and cleanup active effects
function EffectsController:UpdateActiveEffects()
    local currentTime = tick()

    for i = #activeEffects, 1, -1 do
        local effect = activeEffects[i]

        -- Check if effect has expired
        if currentTime - effect.startTime > effect.duration + 1 then
            -- Force cleanup if still exists
            if effect.part and effect.part.Parent then
                effect.part:Destroy()
            end
            if effect.tween then
                effect.tween:Cancel()
            end
            if effect.connection then
                effect.connection:Disconnect()
            end

            table.remove(activeEffects, i)
        end
    end
end

-- Remove specific effect from active list
function EffectsController:RemoveActiveEffect(targetEffect: Effect)
    for i, effect in ipairs(activeEffects) do
        if effect == targetEffect then
            table.remove(activeEffects, i)
            break
        end
    end
end

-- Cleanup all effects
function EffectsController:Cleanup()
    -- Clean up active effects
    for _, effect in ipairs(activeEffects) do
        if effect.part then
            effect.part:Destroy()
        end
        if effect.tween then
            effect.tween:Cancel()
        end
        if effect.connection then
            effect.connection:Disconnect()
        end
    end

    table.clear(activeEffects)

    print("[EffectsController] Effects system cleaned up")
end

return EffectsController
