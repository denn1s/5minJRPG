-- ECS/core/player_animation_system.lua
-- System for handling player animations based on movement input

local Systems = require("ECS.systems")

---@class PlayerAnimationSystem : UpdateSystem
---@field ecs table ECS instance
---@field animationTimer number Timer for tracking frame changes
---@field frameDuration number Duration between animation frames
---@field currentDirection string Current direction the player is facing ("down", "up", "left", "right")
local PlayerAnimationSystem = setmetatable({}, {__index = Systems.UpdateSystem})
PlayerAnimationSystem.__index = PlayerAnimationSystem

---@return PlayerAnimationSystem
function PlayerAnimationSystem.new()
    local system = Systems.UpdateSystem.new()
    setmetatable(system, PlayerAnimationSystem)
    system.animationTimer = 0
    system.frameDuration = 0.2 -- 5 frames per second animation speed
    system.currentDirection = "down" -- Default direction
    return system
end

---@param ecs table
---@param frameDuration? number Optional custom frame duration
---@return PlayerAnimationSystem
function PlayerAnimationSystem:init(ecs, frameDuration)
    Systems.UpdateSystem.init(self, ecs)
    if frameDuration then
        self.frameDuration = frameDuration
    end
    return self
end

---@param dt number Delta time
function PlayerAnimationSystem:run(dt)
    -- Get player entities (entities with both player and sprite components)
    local playerEntities = self.ecs:getEntitiesWithComponent("player")

    for _, entity in ipairs(playerEntities) do
        local sprite = entity:getComponent("sprite")
        local velocity = entity:getComponent("velocity")
        local input = entity:getComponent("input")

        if sprite and input and velocity then
            -- Update animation timer
            self.animationTimer = self.animationTimer + dt

            -- Determine direction and movement state
            local isMoving = false
            local keyMap = input.keyMap

            -- Check each direction key, later ones will override earlier ones
            if love.keyboard.isDown(keyMap.down) then
                sprite.yIndex = 0 -- Down animation row
                isMoving = true
                self.currentDirection = "down"
            end

            if love.keyboard.isDown(keyMap.up) then
                sprite.yIndex = 1 -- Up animation row
                isMoving = true
                self.currentDirection = "up"
            end

            if love.keyboard.isDown(keyMap.left) then
                sprite.yIndex = 2 -- Left animation row
                isMoving = true
                self.currentDirection = "left"
            end

            if love.keyboard.isDown(keyMap.right) then
                sprite.yIndex = 3 -- Right animation row
                isMoving = true
                self.currentDirection = "right"
            end

            -- If no keys are pressed, keep the yIndex for the last direction
            if not isMoving then
                if self.currentDirection == "down" then
                    sprite.yIndex = 0
                elseif self.currentDirection == "up" then
                    sprite.yIndex = 1
                elseif self.currentDirection == "left" then
                    sprite.yIndex = 2
                elseif self.currentDirection == "right" then
                    sprite.yIndex = 3
                end
            end

            -- Animate if moving, otherwise set to standing frame
            if isMoving then
                -- Only change frames when the timer exceeds the frame duration
                if self.animationTimer >= self.frameDuration then
                    -- Reset timer but keep remainder for smoother animations
                    self.animationTimer = self.animationTimer % self.frameDuration

                    -- Update xIndex based on direction
                    if self.currentDirection == "down" or self.currentDirection == "up" then
                        -- For down/up: cycle between frames 1, 2
                        sprite.xIndex = 1 + (sprite.xIndex % 2)
                    else
                        -- For left/right: cycle between frames 0, 1
                        sprite.xIndex = (sprite.xIndex + 1) % 2
                    end
                end
            else
                -- Set to standing frame (first frame in the row)
                sprite.xIndex = 0
            end
        end
    end
end

return PlayerAnimationSystem
