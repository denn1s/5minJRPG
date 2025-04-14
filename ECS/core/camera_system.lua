-- ECS/systems/camera_system.lua
-- Camera system that can follow entities or stay fixed

local Systems = require("ECS.systems")

---@class CameraSystem : UpdateSystem
---@field camera table Camera instance
---@field mode string Camera behavior mode ("follow", "fixed", "path")
---@field target table|nil Target entity to follow (if in follow mode)
---@field targetOffsetX number X offset from target entity
---@field targetOffsetY number Y offset from target entity
---@field smoothness number How smooth camera movement should be (0-1)
local CameraSystem = setmetatable({}, {__index = Systems.UpdateSystem})
CameraSystem.__index = CameraSystem

---@return CameraSystem
function CameraSystem.new()
    local system = Systems.UpdateSystem.new()
    setmetatable(system, CameraSystem)
    system.targetOffsetX = 0
    system.targetOffsetY = 0
    system.smoothness = 0.1 -- Lower = more responsive, higher = smoother
    return system
end

---@param ecs table
---@param camera table
---@param mode string Camera behavior mode ("follow", "fixed", "path")
---@param smoothness? number How smooth camera movement should be (0-1)
---@return CameraSystem
function CameraSystem:init(ecs, camera, mode, smoothness)
    Systems.UpdateSystem.init(self, ecs)
    self.camera = camera
    self.mode = mode or "fixed"
    self.smoothness = smoothness or 0.1
    
    -- This system should always update, even during transitions
    self.ignoreInputLock = true
    
    return self
end

---@param targetEntity table
---@param offsetX? number
---@param offsetY? number
---@return CameraSystem
function CameraSystem:setTarget(targetEntity, offsetX, offsetY)
    self.target = targetEntity
    self.targetOffsetX = offsetX or 0
    self.targetOffsetY = offsetY or 0
    return self
end

---@param dt number Delta time
function CameraSystem:run(dt)
    -- Different behavior based on camera mode
    if self.mode == "fixed" then
        -- Fixed camera - nothing to do
        return
    elseif self.mode == "follow" then
        -- Find player or target entity
        local targetEntity
        if self.target then
            targetEntity = self.target
        else
            -- Default to following player entity
            local playerEntities = self.ecs:getEntitiesWithComponent("player")
            if #playerEntities > 0 then
                targetEntity = playerEntities[1]
            end
        end

        -- Follow the target entity if found
        if targetEntity then
            local transform = targetEntity:getComponent("transform")
            if transform then
                -- Calculate target camera position to center on entity
                local targetX = transform.x - self.camera.width / 2 + self.targetOffsetX
                local targetY = transform.y - self.camera.height / 2 + self.targetOffsetY
                
                -- Apply smoothing using linear interpolation
                if self.smoothness > 0 then
                    local newX = self.camera.x + (targetX - self.camera.x) * self.smoothness
                    local newY = self.camera.y + (targetY - self.camera.y) * self.smoothness
                    self.camera:setPosition(newX, newY)
                else
                    -- Immediate positioning without smoothing
                    self.camera:setPosition(targetX, targetY)
                end
            end
        end
    elseif self.mode == "path" then
        -- Path following camera - future implementation
        -- This would follow a predefined path
    end
end

return CameraSystem
