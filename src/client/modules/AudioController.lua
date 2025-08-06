--!strict
-- AudioController.lua - Audio system for Subway Surfers
local SoundService = game:GetService("SoundService")
local TweenService = game:GetService("TweenService")
local _ReplicatedStorage = game:GetService("ReplicatedStorage")

local AudioController = {}

-- Type definitions
type SoundInstance = {
    sound: Sound,
    originalVolume: number,
    isPlaying: boolean,
}

-- Audio configuration
local AUDIO_CONFIG = {
    masterVolume = 0.8,
    musicVolume = 0.6,
    sfxVolume = 0.7,
    fadeTime = 1.0,
}

-- Sound storage
local sounds: { [string]: SoundInstance } = {}
local currentMusic: Sound? = nil

-- Sound effect IDs (placeholders - replace with actual Roblox audio IDs)
local SOUND_IDS = {
    -- Music
    menu_music = "rbxasset://sounds/electronicpingshort.wav",
    game_music = "rbxasset://sounds/impact_water.mp3",

    -- Sound Effects
    coin_collect = "rbxasset://sounds/button.wav",
    gem_collect = "rbxasset://sounds/switch.wav",
    power_up_collect = "rbxasset://sounds/hit.wav",
    power_up_activate = "rbxasset://sounds/woosh.wav",
    jump = "rbxasset://sounds/footsteps/concrete1.mp3",
    obstacle_hit = "rbxasset://sounds/impact_water.mp3",
    lane_switch = "rbxasset://sounds/footsteps/grass1.mp3",
    speed_boost = "rbxasset://sounds/jet_engine.wav",
}

-- Initialize audio controller
function AudioController:Initialize()
    -- Create sound group for better organization
    local soundGroup = Instance.new("SoundGroup")
    soundGroup.Name = "SubwaySurfers"
    soundGroup.Volume = AUDIO_CONFIG.masterVolume
    soundGroup.Parent = SoundService

    -- Create sound instances
    self:CreateSounds(soundGroup)

    print("[AudioController] Audio system initialized")
end

-- Create all sound instances
function AudioController:CreateSounds(soundGroup: SoundGroup)
    for soundName, soundId in pairs(SOUND_IDS) do
        local sound = Instance.new("Sound")
        sound.Name = soundName
        sound.SoundId = soundId
        sound.SoundGroup = soundGroup

        -- Set volume based on type
        if string.find(soundName, "music") then
            sound.Volume = AUDIO_CONFIG.musicVolume
        else
            sound.Volume = AUDIO_CONFIG.sfxVolume
        end

        -- Set looping for music
        if string.find(soundName, "music") then
            sound.Looped = true
        end

        sound.Parent = SoundService

        -- Store sound instance
        sounds[soundName] = {
            sound = sound,
            originalVolume = sound.Volume,
            isPlaying = false,
        }
    end
end

-- Play sound effect
function AudioController:PlaySFX(soundName: string, volume: number?)
    local soundInstance = sounds[soundName]
    if not soundInstance then
        warn("[AudioController] Sound not found:", soundName)
        return
    end

    local sound = soundInstance.sound

    -- Set volume if specified
    if volume then
        sound.Volume = volume * AUDIO_CONFIG.sfxVolume
    else
        sound.Volume = soundInstance.originalVolume
    end

    -- Play sound
    sound:Play()

    -- Mark as playing
    soundInstance.isPlaying = true

    -- Reset playing flag when finished
    sound.Ended:Connect(function()
        soundInstance.isPlaying = false
    end)
end

-- Play background music
function AudioController:PlayMusic(musicName: string, fadeIn: boolean?)
    local soundInstance = sounds[musicName]
    if not soundInstance then
        warn("[AudioController] Music not found:", musicName)
        return
    end

    local sound = soundInstance.sound

    -- Stop current music
    if currentMusic and currentMusic.IsPlaying then
        self:StopMusic(true) -- Fade out current music
    end

    -- Set as current music
    currentMusic = sound
    soundInstance.isPlaying = true

    if fadeIn then
        -- Start with zero volume and fade in
        sound.Volume = 0
        sound:Play()

        local tweenInfo = TweenInfo.new(AUDIO_CONFIG.fadeTime, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
        local tween = TweenService:Create(sound, tweenInfo, { Volume = soundInstance.originalVolume })
        tween:Play()
    else
        -- Play immediately at full volume
        sound.Volume = soundInstance.originalVolume
        sound:Play()
    end

    print("[AudioController] Playing music:", musicName)
end

-- Stop background music
function AudioController:StopMusic(fadeOut: boolean?)
    if not currentMusic then
        return
    end

    local sound = currentMusic

    if fadeOut then
        -- Fade out and stop
        local tweenInfo = TweenInfo.new(AUDIO_CONFIG.fadeTime, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
        local tween = TweenService:Create(sound, tweenInfo, { Volume = 0 })
        tween:Play()

        tween.Completed:Connect(function()
            sound:Stop()
            sound.Volume = sounds[sound.Name].originalVolume -- Reset volume
        end)
    else
        -- Stop immediately
        sound:Stop()
    end

    -- Update playing flag
    if sounds[sound.Name] then
        sounds[sound.Name].isPlaying = false
    end

    currentMusic = nil
    print("[AudioController] Stopped music")
end

-- Set master volume
function AudioController:SetMasterVolume(volume: number)
    AUDIO_CONFIG.masterVolume = math.clamp(volume, 0, 1)

    local soundGroup = SoundService:FindFirstChild("SubwaySurfers") :: SoundGroup?
    if soundGroup then
        soundGroup.Volume = AUDIO_CONFIG.masterVolume
    end
end

-- Set music volume
function AudioController:SetMusicVolume(volume: number)
    AUDIO_CONFIG.musicVolume = math.clamp(volume, 0, 1)

    -- Update all music sounds
    for soundName, soundInstance in pairs(sounds) do
        if string.find(soundName, "music") then
            soundInstance.originalVolume = AUDIO_CONFIG.musicVolume
            if soundInstance.isPlaying then
                soundInstance.sound.Volume = AUDIO_CONFIG.musicVolume
            end
        end
    end
end

-- Set SFX volume
function AudioController:SetSFXVolume(volume: number)
    AUDIO_CONFIG.sfxVolume = math.clamp(volume, 0, 1)

    -- Update all SFX sounds
    for soundName, soundInstance in pairs(sounds) do
        if not string.find(soundName, "music") then
            soundInstance.originalVolume = AUDIO_CONFIG.sfxVolume
        end
    end
end

-- Convenient methods for common sounds
function AudioController:PlayCoinCollect()
    self:PlaySFX("coin_collect", 0.8)
end

function AudioController:PlayGemCollect()
    self:PlaySFX("gem_collect", 0.9)
end

function AudioController:PlayPowerUpCollect()
    self:PlaySFX("power_up_collect", 1.0)
end

function AudioController:PlayPowerUpActivate()
    self:PlaySFX("power_up_activate", 0.9)
end

function AudioController:PlayJump()
    self:PlaySFX("jump", 0.6)
end

function AudioController:PlayObstacleHit()
    self:PlaySFX("obstacle_hit", 1.0)
end

function AudioController:PlayLaneSwitch()
    self:PlaySFX("lane_switch", 0.4)
end

function AudioController:PlaySpeedBoost()
    self:PlaySFX("speed_boost", 0.7)
end

-- Play menu music
function AudioController:PlayMenuMusic()
    self:PlayMusic("menu_music", true)
end

-- Play game music
function AudioController:PlayGameMusic()
    self:PlayMusic("game_music", true)
end

-- Get audio settings for UI
function AudioController:GetAudioSettings()
    return {
        masterVolume = AUDIO_CONFIG.masterVolume,
        musicVolume = AUDIO_CONFIG.musicVolume,
        sfxVolume = AUDIO_CONFIG.sfxVolume,
    }
end

-- Load audio settings
function AudioController:LoadAudioSettings(settings: { [string]: number })
    if settings.masterVolume then
        self:SetMasterVolume(settings.masterVolume)
    end
    if settings.musicVolume then
        self:SetMusicVolume(settings.musicVolume)
    end
    if settings.sfxVolume then
        self:SetSFXVolume(settings.sfxVolume)
    end
end

-- Cleanup audio system
function AudioController:Cleanup()
    -- Stop all sounds
    for _, soundInstance in pairs(sounds) do
        soundInstance.sound:Stop()
        soundInstance.sound:Destroy()
    end

    -- Clear storage
    table.clear(sounds)
    currentMusic = nil

    -- Remove sound group
    local soundGroup = SoundService:FindFirstChild("SubwaySurfers")
    if soundGroup then
        soundGroup:Destroy()
    end

    print("[AudioController] Audio system cleaned up")
end

return AudioController
