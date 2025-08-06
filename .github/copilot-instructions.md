# Copilot Instructions für Roblox Subway Surfers Projekt

## 🎯 Projekt-Überblick
Dieses ist ein **Roblox Subway Surfers Clone** entwickelt in **Luau** mit **Rojo** für Synchronisierung und **GitHub Copilot** für KI-Unterstützung. Das Projekt folgt einer strikten **Client-Server Architektur** für performantes Multiplayer-Gameplay.

## 🏗️ Architektur-Kernprinzipien

### Service-Pattern mit Initialisierung
Alle Server-Services folgen dem Pattern in `src/server/ServiceInitializer.server.lua`:
- Services werden in definierter Reihenfolge geladen
- Jeder Service implementiert `:Initialize()` Methode
- Nutze `pcall()` für kritische Operationen
- BoolValue Signals im ReplicatedStorage zeigen Service-Status an

```lua
-- Standard Service-Structure
local ServiceName = {}
function ServiceName:Initialize()
    local success = pcall(function()
        self:SetupEventListeners()
        -- Setup-Code hier
    end)
    return success
end
```

### Client-Server Kommunikation
**RemoteEvents** sind in `default.project.json` definiert und werden automatisch erstellt:
- `PlayerAction` - Client-Eingaben an Server
- `GameStateChanged` - Server-Gamestate an Clients
- `ScoreUpdate` - Score-Updates an Clients
- `PowerUpActivated/Deactivated` - PowerUp-Events

**Pattern:** Immer Server-seitige Validierung:
```lua
RemoteEvent.OnServerEvent:Connect(function(player, data)
    if typeof(data) ~= "table" then return end
    if not data.action then return end
    -- Verarbeite validierte Daten
end)
```

### Shared Configuration System
`src/shared/GameConfig.lua` ist die **zentrale Konfiguration** für alle Gameplay-Parameter:
- Player-Einstellungen (Geschwindigkeit, Sprungkraft)
- Gameplay-Balance (Spawn-Raten, Score-Multiplikatoren)
- World-Generation Parameter
- Alle Änderungen hier wirken sich auf Server UND Client aus

## 🎮 Gameplay-Systeme

### Lane-Based Movement
Der `EnhancedPlayerController` implementiert **3-Lane Bewegung** wie im originalen Subway Surfers:
- Lane 0 (links), Lane 1 (mitte), Lane 2 (rechts)
- Smooth Tweening zwischen Lanes mit TweenService
- Separate Sprung/Rutsch-Mechanik unabhängig von Lane-Bewegung

### World Generation Hybrid-Architektur
**Zwei koordinierte Systeme** für Welt-Generierung:
- `DynamicWorldGenerator` - Endlose Object-Spawns (Coins, Obstacles, PowerUps)
- `SegmentSpawner` - Track-Segment Erstellung mit Templates
- **Integration Point:** Beide nutzen `SubwaySurfersGameplay.GetLanePosition()` für Konsistenz

```lua
-- Shared Lane System über SubwaySurfersGameplay
local laneX = SubwaySurfersGameplay.GetLanePosition(lane) -- -8, 0, 8
local obstacle = createObstacle()
obstacle.Position = Vector3.new(laneX, 3, zPosition)
```

### Object Pooling System
`src/shared/ObjectPool.lua` ist **kritisch für Performance**:
- Verhindert Garbage Collection durch Wiederverwendung von Objekten
- Nutze für Obstacles, Collectibles, Effects
- Implementiert Typ-sichere Pools mit Export Types

```lua
-- Object Pool Verwendung
local pool = ObjectPool.new({
    initialSize = 10,
    maxSize = 50,
    createFunction = function() return createObstacle() end,
    resetFunction = function(obj) obj.CFrame = CFrame.new() end
})
```

## 🔧 Development Workflow

### Build-System (Rojo)
- `npm run build` - TypeScript compilation
- **Rojo: Start Server** Task - Live-Sync mit Roblox Studio (Port 34872)
- **Rojo: Build** Task - Erstellt `build/game.rbxlx` für Studio Import
- **StyLua: Format All** - Code-Formatierung (konfiguriert in `stylua.toml`)

### Type Safety mit Luau
**Verwende immer** `--!strict` am Dateianfang:
```lua
--!strict
-- Export Types für bessere Copilot-Unterstützung
export type PlayerState = {
    lane: number,
    isJumping: boolean,
    isSliding: boolean
}
```

### Debugging Pattern
Services loggen Status mit strukturierten Messages:
- `🔧` für Service-Initialisierung
- `✅` für erfolgreiche Operationen
- `⚠️` für Warnungen
- `❌` für Fehler

## 🎯 Copilot-Optimierungen

### File Naming Convention
- `.server.lua` - Server-only Scripts
- `.client.lua` - Client-only Scripts
- `.module.lua` - Shared Modules (optional, meist nur `.lua`)

### Kommentar-Patterns für bessere AI-Suggestions
```lua
-- Spieler-Controller für Endless Runner Spiel
-- Verwaltet Bewegung in drei Bahnen mit Sprung/Rutsch-Mechanik
local PlayerController = {}

-- Typ-Definitionen am Anfang für Copilot-Context
type PlayerState = { -- Struktur hier }
```

### Service Dependencies
Services haben klare Abhängigkeiten (dokumentiert in `ServiceInitializer`):
1. RemoteEventsService (Remote-Kommunikation)
2. PlayerDataService (Spieler-Daten)
3. GameLoopManager (Game-Loop)
4. WorldBuilder & DynamicWorldGenerator (Welt-Systeme)
5. Andere Game-Services

### Shared Module Loading Pattern
**Kritisches Pattern** für zirkuläre Abhängigkeiten vermeiden:
```lua
-- Demand Loading Pattern in shared modules
local _GameConfig = nil -- Loaded on demand
local function getGameConfig()
    if not _GameConfig then
        _GameConfig = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("GameConfig"))
    end
    return _GameConfig
end
```

## ⚡ Performance Patterns

### RunService Integration
Nutze **RunService.Heartbeat** für kontinuierliche Updates:
```lua
local connection
connection = RunService.Heartbeat:Connect(function(deltaTime)
    -- Update-Logic mit deltaTime
end)
```

### Memory Management
- Object Pooling für häufig erstellte Objekte
- Disconnect Connections bei Cleanup
- Nutze weak references wo möglich
- `obj.Parent = nil` statt `obj:Destroy()` für poolbare Objekte

## 🚨 Kritische Patterns

### World System Integration
**Dual-System Koordination:** `WorldBuilder` erstellt statische Welt, `DynamicWorldGenerator` + `SegmentSpawner` arbeiten zusammen für endlose Generation. Beide Systeme müssen `SubwaySurfersGameplay.GetLanePosition()` für Lane-Konsistenz nutzen.

### Wait-for-Child Pattern
**Immer** mit Timeout verwenden:
```lua
local RemoteEvents = ReplicatedStorage:WaitForChild("RemoteEvents", 5)
if not RemoteEvents then
    warn("RemoteEvents nicht gefunden!")
    return
end
```

### Error Handling
Kritische Operationen in `pcall()` wrappen:
```lua
local success, result = pcall(function()
    return riskyOperation()
end)
if not success then
    warn("Operation fehlgeschlagen:", result)
end
```

### Circular Dependency Prevention
Nutze **loadModuleSafe()** Pattern in shared modules:
```lua
local function loadModuleSafe(path: string)
    local success, module = pcall(function()
        return require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild(path))
    end)
    if not success then
        warn("[ModuleName] Failed to load module:", path)
        return nil
    end
    return module
end
```

---

**Besonderheiten dieses Codebases:** Deutsche Kommentare, strikte Type-Annotations, Service-Pattern mit BoolValue-Signaling, zentrale GameConfig, Object Pooling für Performance, Dual-World-Generation (WorldBuilder + DynamicWorldGenerator/SegmentSpawner), Demand-Loading für Circular-Dependency Prevention.
