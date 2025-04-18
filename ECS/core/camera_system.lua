-- ECS/systems/camera_system.lua
-- Simplified camera system that always follows a target if available

local Systems = require("ECS.systems")

---@class CameraSystem : UpdateSystem
---@field camera table
---@field target table|nil
---@field targetOffsetX number
---@field targetOffsetY number
local CameraSystem = setmetatable({}, {__index = Systems.UpdateSystem})
CameraSystem.__index = CameraSystem

---@return CameraSystem
function CameraSystem.new()
    local system = Systems.UpdateSystem.new()
    setmetatable(system, CameraSystem)
    system.targetOffsetX = 0
    system.targetOffsetY = 0
    return system
end

---@param ecs table
---@param camera table
---@return CameraSystem
function CameraSystem:init(ecs, camera)
    Systems.UpdateSystem.init(self, ecs)
    self.camera = camera
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

---@param dt number
function CameraSystem:run(dt)
    local target = self.target

    if not target then
        -- Try to fallback to player
        local playerEntities = self.ecs:getEntitiesWithComponent("player")
        if #playerEntities > 0 then
            target = playerEntities[1]
        end
    end

    if target then
        local transform = target:getComponent("transform")
        if transform then
            local targetX = transform.x - self.camera.width / 2 + self.targetOffsetX
            local targetY = transform.y - self.camera.height / 2 + self.targetOffsetY
            self.camera:setPosition(targetX, targetY)
        end
    end
end

return CameraSystem

