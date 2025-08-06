--!strict
-- Spieler-Controller für Endless Runner Spiel
-- Verwaltet Bewegung in drei Bahnen mit Sprung/Rutsch-Mechanik
local EnhancedPlayerController = {}

-- Typ-Definitionen
export type PlayerState = {
    lane: number,
    isJumping: boolean,
    isSliding: boolean,
}

export type EnhancedPlayerController = {
    MoveToLane: (self: EnhancedPlayerController, lane: number) -> (),
    Jump: (self: EnhancedPlayerController) -> (),
    Slide: (self: EnhancedPlayerController) -> (),
}

function EnhancedPlayerController.new(): EnhancedPlayerController
    -- Initialisierungscode hier
    return setmetatable({}, { __index = EnhancedPlayerController }) :: any
end

function EnhancedPlayerController:MoveToLane(lane: number)
    -- Logik für das Bewegen zwischen den Bahnen
end

function EnhancedPlayerController:Jump()
    -- Sprung-Logik hier
end

function EnhancedPlayerController:Slide()
    -- Rutsch-Logik hier
end

return EnhancedPlayerController
