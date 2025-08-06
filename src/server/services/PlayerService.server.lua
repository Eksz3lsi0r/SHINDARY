--!strict
-- Diese Funktion aktualisiert die Spieler-Daten mit Typ-Sicherheit
export type PlayerData = {
    userId: number,
    displayName: string,
    coins: number,
    level: number,
}

function updatePlayerData(player: Player, data: PlayerData): boolean
    -- Implementation mit Typ-Validierung
    local success = pcall(function()
        -- Potenziell fehleranfällige Operation
        player:SetAttribute("coins", data.coins)
        player:SetAttribute("level", data.level)
    end)

    if not success then
        warn("Aktualisierung der Spieler-Daten fehlgeschlagen")
        return false
    end

    return true
end
