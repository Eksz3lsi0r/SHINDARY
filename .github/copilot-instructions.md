# Copilot Instructions für Roblox Subway Surfers Projekt

## 🎯 Projekt-Überblick
Dieses ist ein **Roblox Subway Surfers Clone** entwickelt in **Luau** mit **Rojo** für Synchronisierung und **GitHub Copilot** für KI-Unterstützung. Das Projekt folgt einer strikten **Client-Server Architektur** für performantes Multiplayer-Gameplay.

## 🏗️ Architektur-Kernprinzipien

### Service-Pattern mit koordinierter Initialisierung
Alle Server-Services folgen dem Pattern in `src/server/ServiceInitializer.server.lua`:
- Services werden in **definierter Reihenfolge** geladen (RemoteEventsService → PlayerDataService → GameLoopManager → WorldBuilder)
- Jeder Service implementiert `:Initialize()` Methode mit `pcall()` Fehlerbehandlung
- **BoolValue Signals** im ReplicatedStorage (`ServerReady`, `GameManagerReady`, `ServicesReady`) zeigen Service-Status an
- **Performance Monitoring** mit strukturiertem Logging (`🔧`, `✅`, `⚠️`, `❌`)

```lua
-- Standard Service-Structure mit verbesserter Fehlerbehandlung
local ServiceName = {}
function ServiceName:Initialize()
    local success = pcall(function()
        self:SetupEventListeners()
        self:SetupPerformanceMonitoring() -- Neu: Performance-Tracking
        -- Setup-Code hier
    end)
    return success
end
```

### Client-Server Kommunikation mit Validierung
**RemoteEvents** sind in `default.project.json` definiert und werden automatisch erstellt:
- `PlayerAction` - Client-Eingaben an Server (mit Rate-Limiting)
- `GameStateChanged` - Server-Gamestate an Clients
- `ScoreUpdate` - Score-Updates an Clients
- `PowerUpActivated/Deactivated` - PowerUp-Events mit Typ-Validierung

**Kritisches Pattern:** Immer Server-seitige Validierung mit Rate-Limiting:
```lua
RemoteEvent.OnServerEvent:Connect(function(player, action, data)
    -- 1. Type Validation
    if typeof(data) ~= "table" then return end
    if not action or typeof(action) ~= "string" then return end

    -- 2. Rate Limiting (neu implementiert)
    if not self:CheckRateLimit(player, action) then
        warn("Rate limit exceeded for", player.Name, action)
        return
    end

    -- 3. Process validated data
    self:ProcessPlayerAction(player, action, data)
end)
```

### Shared Configuration System mit Hot-Reload
`src/shared/GameConfig.lua` ist die **zentrale Konfiguration** für alle Gameplay-Parameter:
- Player-Einstellungen (Geschwindigkeit, Sprungkraft, Gesundheit)
- Gameplay-Balance (Spawn-Raten, Score-Multiplikatoren, Schwierigkeitsgrade)
- World-Generation Parameter (Platform-Größen, Spawn-Distanzen)
- **Alle Änderungen hier wirken sich synchron auf Server UND Client aus**
- Nutze **demand loading** Pattern für Performance

## 🎮 Gameplay-Systeme

### Lane-Based Movement System
Der `EnhancedPlayerController` implementiert **3-Lane Bewegung** wie im originalen Subway Surfers:
- **Lane System:** Lane -1 (links), Lane 0 (mitte), Lane 1 (rechts) mit X-Positionen -8, 0, 8
- **Smooth Tweening** zwischen Lanes mit TweenService (`tweenDuration = 0.3`)
- **Separate Mechaniken:** Sprung/Rutsch unabhängig von Lane-Bewegung
- **State Management:** `MovementStates.RUNNING/JUMPING/ROLLING/SLIDING/FALLING`

### World Generation Dual-System Architektur
**Zwei koordinierte Systeme** für nahtlose Welt-Generierung:
- `WorldBuilder` - Statische Basis-Welt und initiale Track-Erstellung
- `DynamicWorldGenerator` - Endlose Object-Spawns (Coins, Obstacles, PowerUps)
- `SegmentSpawner` - Track-Segment Templates und prozeduale Erstellung
- **Kritischer Integration Point:** Alle Systeme nutzen `SubwaySurfersGameplay.GetLanePosition(lane)` für konsistente Positionierung

```lua
-- Shared Lane System für konsistente Positionierung
local laneX = SubwaySurfersGameplay.GetLanePosition(lane) -- Gibt -8, 0, oder 8 zurück
local obstacle = createObstacle()
obstacle.CFrame = CFrame.new(laneX, 3, zPosition)
```

### Object Pooling System für Performance
`src/shared/ObjectPool.lua` ist **kritisch für Performance** und Memory Management:
- Verhindert Garbage Collection durch intelligente Wiederverwendung
- **Typ-sichere Pools** mit Export Types für bessere Copilot-Unterstützung
- Nutze für alle häufig erstellten Objekte: Obstacles, Collectibles, Visual Effects
- **Reset-Funktionen** für saubere Objektwiederverwendung

```lua
-- Object Pool Verwendung mit Type Safety
local pool = ObjectPool.new({
    initialSize = 10,
    maxSize = 50,
    createFunction = function() return createObstacle() end,
    resetFunction = function(obj)
        obj.CFrame = CFrame.new()
        obj.Velocity = Vector3.new()
        obj.Parent = nil
    end
})
```

### Power-Up System mit Effekt-Management
Power-Ups folgen dem `SubwaySurfersGameplay.PowerUps` Schema:
- **JETPACK** (8s) - Flug-Mechanik mit Y-Achsen Kontrolle
- **SUPER_SNEAKERS** (10s) - Erhöhte Sprungkraft
- **COIN_MAGNET** (15s) - Automatische Coin-Sammlung
- **MULTIPLIER** (20s) - Doppelte Score-Punkte

## 🔧 Development Workflow

### Build-System mit Rojo Integration
- **`npm run build`** - TypeScript compilation und Asset-Processing
- **VS Code Task: "Rojo: Start Server"** - Live-Sync mit Roblox Studio (Port 34872)
- **VS Code Task: "Rojo: Build"** - Erstellt `build/game.rbxlx` für Studio Import
- **VS Code Task: "StyLua: Format All"** - Code-Formatierung nach `stylua.toml` Konfiguration
- **Automatische Sourcemap-Generierung** für besseres Debugging

### Enhanced Type Safety mit Luau
**Verwende immer** `--!strict` am Dateianfang für maximale Type Safety:
```lua
--!strict
-- Export Types für bessere Copilot-Unterstützung und IntelliSense
export type PlayerState = {
    lane: number,
    isJumping: boolean,
    isSliding: boolean,
    movementState: string,
    health: number
}

export type GameConfig = {
    Player: PlayerConfig,
    Gameplay: GameplayConfig,
    World: WorldConfig
}
```

### Server Readiness Pattern mit Multi-Level Validation
**Kritisches Pattern** für zuverlässige Client-Server Synchronisation:
```lua
-- Client-seitige Server-Readiness Prüfung
local function isServerFullyReady()
    -- 1. Module Readiness
    if not gameModulesReady then return false end

    -- 2. Server Signals
    local serverReady = ReplicatedStorage:FindFirstChild("ServerReady")
    local gameManagerReady = ReplicatedStorage:FindFirstChild("GameManagerReady")

    if not (serverReady and serverReady.Value) then return false end
    if not (gameManagerReady and gameManagerReady.Value) then return false end

    -- 3. RemoteFunction Availability
    local remoteStatus = pcall(function()
        return ReplicatedStorage.RemoteFunctions.GetServerStatus:InvokeServer()
    end)

    return remoteStatus
end
```

### Enhanced Debugging mit strukturiertem Logging
Services nutzen **konsistente Log-Patterns** für bessere Debugging-Erfahrung:
- `🔧` für Service-Initialisierung und Setup
- `✅` für erfolgreiche Operationen und Verbindungen
- `⚠️` für Warnungen und wiederherstellbare Fehler
- `❌` für kritische Fehler und Failed Operations
- `🎮` für Gameplay-Events und Player-Aktionen
- `📤📥` für Client-Server Kommunikation

## 🎯 Copilot-Optimierungen

### File Naming Convention für bessere AI-Erkennung
- `.server.lua` - Server-only Scripts (automatisch in ServerScriptService)
- `.client.lua` - Client-only Scripts (automatisch in StarterPlayerScripts)
- `.module.lua` - Shared Modules (optional suffix, meist nur `.lua`)
- **Nutze beschreibende Namen:** `EnhancedPlayerController.client.lua`, `RemoteEventsService.lua`

### Enhanced Comment Patterns für maximale AI-Unterstützung
```lua
-- Spieler-Controller für Endless Runner Spiel
-- Verwaltet Bewegung in drei Bahnen mit Sprung/Rutsch-Mechanik
-- Integriert mit SubwaySurfersGameplay für Lane-Konsistenz
local PlayerController = {}

-- Type Definitions am Anfang für vollständigen Copilot-Context
export type PlayerState = {
    lane: number,              -- -1, 0, 1 für Links/Mitte/Rechts
    isJumping: boolean,        -- Sprung-Zustand
    movementState: string,     -- Aktueller Bewegungszustand
    lastInputTime: number      -- Für Input-Debouncing
}
```

### Service Dependencies mit Enhanced Loading Order
Services haben **strikt definierte Abhängigkeiten** (dokumentiert in `ServiceInitializer`):
1. **RemoteEventsService** - Remote-Kommunikations-Foundation
2. **PlayerDataService** - Spieler-Daten und Session-Management
3. **GameLoopManager** - Core Game-Loop und State-Management
4. **WorldBuilder & DynamicWorldGenerator** - Koordinierte Welt-Systeme
5. **Specialized Services** - PowerUpService, ScoreService, ObstacleService

### Enhanced Shared Module Loading Pattern
**Demand Loading mit Circular Dependency Prevention:**
```lua
-- Optimized loading pattern für shared modules
local _GameConfig = nil -- Cached module reference
local function getGameConfig()
    if not _GameConfig then
        local success, module = pcall(function()
            return require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("GameConfig"))
        end)

        if success then
            _GameConfig = module
        else
            warn("[ModuleName] Failed to load GameConfig:", module)
            return nil
        end
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
