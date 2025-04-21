-- ECS/transition.lua
-- Scene transition system with fade effects

local ECS = require("ECS.ecs")

---@class Transition
---@field active boolean Whether a transition is currently active
---@field type string The type of transition ("fade_out", "fade_in", "none")
---@field duration number The duration of the transition in seconds
---@field elapsed number The elapsed time of the current transition
---@field targetScene string|nil The name of the scene to transition to
---@field preserveCurrentScene boolean Whether to preserve the current scene as previous scene
---@field fadeLevel number Current fade level (1-4 for GameBoy style)
---@field inputLocked boolean Whether input is locked during transitions
---@field waitForNextFrame boolean Whether to wait one frame before starting fade-in
local Transition = {
    active = false,
    type = "none",
    duration = 0.5,  -- Default transition duration (can be changed)
    elapsed = 0,
    targetScene = nil,
    preserveCurrentScene = false,
    fadeLevel = 4,    -- GameBoy style has 4 colors (4 is lightest, 1 is darkest)
    inputLocked = false,
    waitForNextFrame = false,  -- Flag to wait one frame before starting fade-in
}

-- Create a new transition
---@param transitionType string
---@param targetScene string|nil
---@param preserveCurrentScene boolean
---@param duration number|nil
---@param targetPlayerPosition? table|nil   -- a table with x, y target player position
---@return boolean
function Transition:start(transitionType, targetScene, preserveCurrentScene, duration, targetPlayerPosition)
    if self.active then
        print("[Transition] A transition is already in progress (", transitionType, targetScene,")")
        return false
    end
    print("Starting transition", transitionType)
    if targetScene ~= nil then
        print("At end, we will load scene", targetScene)
    end

    self.active = true
    self.type = transitionType
    self.targetScene = targetScene
    self.preserveCurrentScene = preserveCurrentScene or false
    self.duration = duration or self.duration  -- Use provided duration or default
    self.elapsed = 0
    self.targetPlayerPosition = targetPlayerPosition

    -- Set initial fade level based on transition type
    if transitionType == "fade_out" then
        self.fadeLevel = 4  -- Start from lightest (full brightness)
    elseif transitionType == "fade_in" then
        self.fadeLevel = 1  -- Start from darkest
    end

    -- Lock input during transition
    self.inputLocked = true

    return true
end

-- Update the transition state
---@param dt number
---@param sceneManager table
---@return boolean Whether the transition is still active
function Transition:update(dt, sceneManager)
    if not self.active then return false end

    -- Handle wait-for-next-frame flag for fade-in after scene change
    if self.waitForNextFrame then
        self.waitForNextFrame = false
        self:start("fade_in", nil, false, self.duration)
        return true
    end

    self.elapsed = self.elapsed + dt

    -- Calculate progress from 0 to 1
    local progress = math.min(1, self.elapsed / self.duration)
    if self.type == "fade_out" then
        -- For fade out: 4 -> 1 (lightest to darkest)
        -- We want to step through 4 levels, so we divide the progress into 3 sections
        self.fadeLevel = 4 - math.floor(progress * 3)
        if self.fadeLevel < 1 then self.fadeLevel = 1 end

        -- If fade out complete and we have a target scene, switch to it and start fade in
        if progress >= 1 then
            if self.targetScene then
                -- Save current values before scene transition
                local targetScene = self.targetScene
                local preserveScene = self.preserveCurrentScene
                local duration = self.duration

                -- Switch to the new scene
                print("calling transition to scene")
                sceneManager:transitionToScene(targetScene, preserveScene)

                -- change player position if needed
                if self.targetPlayerPosition ~= nil then
                    local playerEntities = ECS:getEntitiesWithComponent("player")
                    for _, entity in ipairs(playerEntities) do
                        local t = entity:getComponent("transform")
                        t.x = self.targetPlayerPosition.x
                        t.y = self.targetPlayerPosition.y
                    end
                end
                -- Set up the fade-in to start on next frame
                -- This is to ensure the scene has fully loaded before we start fade-in
                self.active = true
                self.type = "fade_in"  -- Temporary state
                self.targetScene = nil
                self.waitForNextFrame = true
                self.duration = duration
                self.elapsed = 0

                return true
            else
                -- Just end the transition if we don't have a target scene
                self.active = false
                self.inputLocked = false
                return false
            end
        end
    elseif self.type == "fade_in" then
        -- For fade in: 1 -> 4 (darkest to lightest)
        self.fadeLevel = 1 + math.floor(progress * 3)
        if self.fadeLevel > 4 then self.fadeLevel = 4 end

        -- If fade in complete, end the transition
        if progress >= 1 then
            self.active = false
            self.inputLocked = false
            print("fade in complete")
            if self.targetScene ~= nil then
                print("transitioning to scene")
                local targetScene = self.targetScene
                local preserveScene = self.preserveCurrentScene
                sceneManager:transitionToScene(targetScene, preserveScene)
            end
            return false
        end
    end

    return true
end

-- Get the current color index adjustment
-- This is how much to subtract from a normal color index to get the faded color
---@param originalIndex number The original color index (1-4)
---@return number The adjusted color index (1-4)
function Transition:getColor(originalIndex)
    if not self.active then return originalIndex end

    -- In GameBoy style, we want to shift everything toward the darker end (lower indices)
    -- But never go below 1 (the darkest color)
    local newIndex = math.min(originalIndex, self.fadeLevel)
    return math.max(1, newIndex)
end

-- Check if input should be locked
---@return boolean
function Transition:isInputLocked()
    return self.inputLocked
end

return Transition
