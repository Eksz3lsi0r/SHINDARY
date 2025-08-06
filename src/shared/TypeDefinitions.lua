-- TypeDefinitions.lua - Zentrale Type-Definitionen für Type-Safety
--!strict

-- Player State Type
export type PlayerState = {
    lane: number,
    isJumping: boolean,
    isSliding: boolean,
    speed: number,
    distance: number,
    isGameActive: boolean,
}

-- Connection Types für bessere nil-handling
export type OptionalConnection = RBXScriptConnection?
export type OptionalTween = Tween?

-- Enhanced Player Controller Interface
export type IEnhancedPlayerController = {
    player: Player,
    character: Model?,
    humanoid: Humanoid?,
    rootPart: BasePart?,
    state: PlayerState,
    forwardMovementConnection: OptionalConnection,
    inputConnection: OptionalConnection,
    movementTween: OptionalTween,
}

-- Game Configuration Type
export type GameConfig = {
    MOVEMENT_SPEED: number,
    FORWARD_SPEED: number,
    JUMP_HEIGHT: number,
    JUMP_DURATION: number,
    SLIDE_DURATION: number,
    LANE_WIDTH: number,
}

-- Camera Controller Type
export type ICameraController = {
    Camera: Camera,
    Player: Player?,
    RootPart: BasePart?,
    CameraConnection: OptionalConnection,
    OriginalCFrame: CFrame?,
    IsGameCameraActive: boolean,
}

-- Game Session Type
export type GameSession = {
    startTime: number,
    initiatingPlayer: Player,
}

-- Game Coordinator Status
export type GameCoordinatorStatus = {
    initialized: boolean,
    activeSession: boolean,
    worldGeneratorActive: boolean,
    gameLoopState: string,
    playerCount: number,
}

return {}
