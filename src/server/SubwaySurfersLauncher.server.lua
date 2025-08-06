-- Subway Surfers Game Launcher
-- Startet das komplette Spiel System
--!strict

local GameCoordinator = require(script.Parent.GameCoordinator)

-- Initialize the complete game system
print("🎮 SUBWAY SURFERS GAME - Starting...")
print("🚀 Loading Game Coordinator...")

local coordinator = GameCoordinator.new()
coordinator:initialize()

-- Store globally for other scripts to access
_G.SubwaySurfersGame = coordinator

print("✅ SUBWAY SURFERS GAME - Ready to play!")
print("👋 Players can now join and the game will start automatically")

-- Status check every 30 seconds
spawn(function()
    while true do
        wait(30)
        local status = coordinator:getStatus()
        print(
            `📊 Game Status: {status.playerCount} players, Active: {status.activeSession}, World: {status.worldGeneratorActive}`
        )
    end
end)
