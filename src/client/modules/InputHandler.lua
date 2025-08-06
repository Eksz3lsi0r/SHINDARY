--!strict
-- InputHandler.lua - Enhanced input management for Subway Surfers
local GuiService = game:GetService("GuiService")
local UserInputService = game:GetService("UserInputService")

local InputHandler = {}

-- Types
export type InputCallback = (inputType: string, inputValue: any?) -> ()
export type TouchGesture = "swipeLeft" | "swipeRight" | "swipeUp" | "swipeDown" | "tap"

-- Private variables
local callbacks: { [string]: InputCallback } = {}
local touchStartPosition: Vector2?
local lastTouchTime = 0
local SWIPE_THRESHOLD = 50 -- Minimum distance for swipe
local TAP_TIME_THRESHOLD = 0.3 -- Maximum time for tap

-- Input mapping
local INPUT_MAPPINGS = {
    -- Movement
    [Enum.KeyCode.A] = "moveLeft",
    [Enum.KeyCode.Left] = "moveLeft",
    [Enum.KeyCode.D] = "moveRight",
    [Enum.KeyCode.Right] = "moveRight",

    -- Actions
    [Enum.KeyCode.W] = "jump",
    [Enum.KeyCode.Up] = "jump",
    [Enum.KeyCode.Space] = "jump",
    [Enum.KeyCode.S] = "slide",
    [Enum.KeyCode.Down] = "slide",

    -- Game control
    [Enum.KeyCode.R] = "startGame",
    [Enum.KeyCode.Escape] = "pauseGame",
    [Enum.KeyCode.P] = "pauseGame",
}

-- Register callback for input events
function InputHandler.RegisterCallback(inputType: string, callback: InputCallback)
    callbacks[inputType] = callback
    print("[InputHandler] Registered callback for:", inputType)
end

-- Fire callback if registered
local function fireCallback(inputType: string, inputValue: any?)
    local callback = callbacks[inputType]
    if callback then
        spawn(function()
            callback(inputType, inputValue)
        end)
    end
end

-- Handle keyboard input
local function handleKeyboardInput(input: InputObject, gameProcessed: boolean)
    if gameProcessed then
        return
    end

    local inputType = INPUT_MAPPINGS[input.KeyCode]
    if inputType then
        print("[InputHandler] Keyboard input:", input.KeyCode.Name, "->", inputType)
        fireCallback(inputType, nil)
    end
end

-- Detect touch gestures
local function detectTouchGesture(startPos: Vector2, endPos: Vector2, duration: number): TouchGesture?
    local deltaX = endPos.X - startPos.X
    local deltaY = endPos.Y - startPos.Y
    local distance = math.sqrt(deltaX ^ 2 + deltaY ^ 2)

    -- Check for tap (short duration, small movement)
    if duration <= TAP_TIME_THRESHOLD and distance < SWIPE_THRESHOLD then
        return "tap"
    end

    -- Check for swipe (sufficient distance)
    if distance >= SWIPE_THRESHOLD then
        local absDeltaX = math.abs(deltaX)
        local absDeltaY = math.abs(deltaY)

        -- Determine primary direction
        if absDeltaX > absDeltaY then
            if deltaX > 0 then
                return "swipeRight"
            else
                return "swipeLeft"
            end
        else
            if deltaY > 0 then
                return "swipeDown"
            else
                return "swipeUp"
            end
        end
    end

    return nil
end

-- Handle touch input
local function handleTouchInput(touch: InputObject, gameProcessed: boolean)
    if gameProcessed then
        return
    end

    local currentTime = tick()

    if touch.UserInputState == Enum.UserInputState.Begin then
        touchStartPosition = Vector2.new(touch.Position.X, touch.Position.Y)
        lastTouchTime = currentTime
    elseif touch.UserInputState == Enum.UserInputState.End and touchStartPosition then
        local duration = currentTime - lastTouchTime
        local endPos = Vector2.new(touch.Position.X, touch.Position.Y)
        local gesture = detectTouchGesture(touchStartPosition, endPos, duration)

        if gesture then
            print("[InputHandler] Touch gesture detected:", gesture)

            -- Map touch gestures to game actions
            if gesture == "swipeLeft" then
                fireCallback("moveLeft", nil)
            elseif gesture == "swipeRight" then
                fireCallback("moveRight", nil)
            elseif gesture == "swipeUp" then
                fireCallback("jump", nil)
            elseif gesture == "swipeDown" then
                fireCallback("slide", nil)
            elseif gesture == "tap" then
                fireCallback("jump", nil) -- Default tap action is jump
            end
        end

        touchStartPosition = nil
    end
end

-- Initialize input handling
function InputHandler.Initialize()
    print("[InputHandler] Initializing input system...")

    -- Keyboard input
    UserInputService.InputBegan:Connect(handleKeyboardInput)

    -- Touch input (mobile)
    UserInputService.TouchStarted:Connect(handleTouchInput)
    UserInputService.TouchEnded:Connect(handleTouchInput)

    -- Gamepad support (future enhancement)
    UserInputService.GamepadConnected:Connect(function(gamepad)
        print("[InputHandler] Gamepad connected:", gamepad)
    end)

    print("[InputHandler] Input system initialized!")
end

-- Get platform-specific controls info
function InputHandler.GetControlsInfo(): { string }
    local platform = GuiService:IsTenFootInterface() and "Console"
        or UserInputService.TouchEnabled and "Mobile"
        or "Desktop"

    if platform == "Mobile" then
        return {
            "Swipe left/right to change lanes",
            "Swipe up to jump",
            "Swipe down to slide",
            "Tap to jump",
        }
    elseif platform == "Console" then
        return {
            "Use D-Pad to move",
            "A to jump",
            "B to slide",
        }
    else -- Desktop
        return {
            "A/D or Arrow Keys to move",
            "W/Space to jump",
            "S to slide",
            "R to restart, Esc to pause",
        }
    end
end

-- Cleanup
function InputHandler.Destroy()
    callbacks = {}
    touchStartPosition = nil
    print("[InputHandler] Input system cleaned up")
end

return InputHandler
