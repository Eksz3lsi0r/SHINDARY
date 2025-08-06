-- GameConstants.lua - Gemeinsame Konstanten für alle Module (circular dependency free)
--!strict

local GameConstants = {}

-- Spiel-Konfiguration (ohne komplexe Abhängigkeiten)
GameConstants.GAME = {
    FORWARD_SPEED = 25,
    LANE_WIDTH = 8,
    LANES = {
        LEFT = -1,
        CENTER = 0,
        RIGHT = 1,
    },
}

-- Lane-System Konstanten
GameConstants.LANE_POSITIONS = {
    [-1] = -8, -- Left lane X position
    [0] = 0, -- Center lane X position
    [1] = 8, -- Right lane X position
}

-- Bewegungs-Konstanten
GameConstants.MOVEMENT = {
    SPEED = 0.2,
    JUMP_HEIGHT = 20,
    JUMP_DURATION = 0.8,
    SLIDE_DURATION = 1.0,
}

-- Einfache Lane-Position Berechnung (ohne externe Abhängigkeiten)
function GameConstants.GetLanePosition(lane: number): number
    return GameConstants.LANE_POSITIONS[lane] or 0
end

-- Power-Up Types (einfache Enums)
GameConstants.POWER_UP_TYPES = {
    JETPACK = "JETPACK",
    COIN_MAGNET = "COIN_MAGNET",
    SUPER_SNEAKERS = "SUPER_SNEAKERS",
    SCORE_MULTIPLIER = "SCORE_MULTIPLIER",
}

-- Obstacle Types (einfache Enums)
GameConstants.OBSTACLE_TYPES = {
    BARRIER = "BARRIER",
    TRAIN = "TRAIN",
    TUNNEL_ENTRANCE = "TUNNEL_ENTRANCE",
}

-- Collectible Types (einfache Enums)
GameConstants.COLLECTIBLE_TYPES = {
    COIN = "COIN",
    LETTER = "LETTER",
    KEY = "KEY",
}

return GameConstants
