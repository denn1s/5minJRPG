-- ECS/core/camera_system.lua
-- System for making the camera follow a target entity (typically the player)

local Systems = require("ECS.systems")

---@class CameraSystem : UpdateSystem
---@field ecs table ECS instance
---@field camera table Camera instance
---@field target table|nil Target entity to follow
---@field offsetX number X offset from target center
---@field offsetY number Y offset from target center
---@field smoothing number Smoothing factor for camera movement (0-1, 0 = instant)
local CameraSystem = setmetatable({}, {__index = Systems.UpdateSystem})
CameraSystem.__index = CameraSystem

---@return CameraSystem
function CameraSystem.new()
    local system = Systems.UpdateSystem.new()
    setmetatable(system, CameraSystem)

    -- Default configuration
    system.offsetX = 0
    system.offsetY = 0
    system.smoothing = 0  -- Default to instant movement (no smoothing)

    -- This system should run even when input is locked (during transitions)
    system.ignoreInputLock = true

    return system
end

---@param ecs table ECS instance
---@param camera table Camera instance
---@return CameraSystem
function CameraSystem:init(ecs, camera)
    Systems.UpdateSystem.init(self, ecs)

    if not camera then
        error("Camera must be provided to CameraSystem")
    end

    self.camera = camera
    return self
end

---@param targetEntity table Entity to follow
---@param offsetX? number X offset from entity center (default: 0)
---@param offsetY? number Y offset from entity center (default: 0)
---@return CameraSystem
function CameraSystem:setTarget(targetEntity, offsetX, offsetY)
    self.target = targetEntity
    self.offsetX = offsetX or 0
    self.offsetY = offsetY or 0
    return self
end

---@param smoothingFactor number Smoothing factor (0-1, 0 = instant, 1 = no movement)
---@return CameraSystem
function CameraSystem:setSmoothing(smoothingFactor)
    self.smoothing = math.max(0, math.min(1, smoothingFactor))
    return self
end

---@param dt number Delta time (unused for instant camera movement)
function CameraSystem:run(_)
    local target = self.target

    -- If no explicit target set, try to find a player entity
    if not target then
        local playerEntities = self.ecs:getEntitiesWithComponent("player")
        if #playerEntities > 0 then
            target = playerEntities[1]
        else
            -- No target, nothing to do
            return
        end
    end

    -- Get the target's transform component
    local transform = target:getComponent("transform")
    if not transform then
        return
    end

    -- Calculate target camera position
    -- Center the camera on the entity, plus any offsets
    local targetX = transform.x - self.camera.width / 2 + self.offsetX
    local targetY = transform.y - self.camera.height / 2 + self.offsetY

    -- Apply smoothing if enabled
    if self.smoothing > 0 then
        -- Linear interpolation between current and target position
        local currentX = self.camera.x
        local currentY = self.camera.y

        targetX = currentX + (targetX - currentX) * (1 - self.smoothing)
        targetY = currentY + (targetY - currentY) * (1 - self.smoothing)
    end

    -- Update camera position (will be clamped to world bounds by the camera)
    self.camera:setPosition(targetX, targetY)
end

return CameraSystem
