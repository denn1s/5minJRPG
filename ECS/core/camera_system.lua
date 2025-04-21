-- ECS/core/camera_system.lua
-- System for making the camera follow a target entity (typically the player)

local Systems = require("ECS.systems")

function followTarget(camera, ecs)
    local target = nil
    local playerEntities = ecs:getEntitiesWithComponent("player")
    if #playerEntities > 0 then
        target = playerEntities[1]
    else
        -- No target, nothing to do
        return
    end

    -- Get the target's transform component
    local transform = target:getComponent("transform")
    if not transform then
        return
    end

    -- Calculate target camera position
    -- Center the camera on the entity, plus any offsets
    local targetX = transform.x - (camera.width / 2) + 8   -- half sprite width
    local targetY = transform.y - (camera.height / 2) + 8
    -- Update camera position (will be clamped to world bounds by the camera)
    camera:setPosition(targetX, targetY)
end

---@class CameraUpdateSystem : UpdateSystem
---@field ecs table ECS instance
---@field camera table Camera instance
---@field target table|nil Target entity to follow
local CameraUpdateSystem = setmetatable({}, {__index = Systems.UpdateSystem})
CameraUpdateSystem.__index = CameraUpdateSystem

---@return CameraUpdateSystem
function CameraUpdateSystem.new()
    local system = Systems.UpdateSystem.new()
    setmetatable(system, CameraUpdateSystem)
    return system
end

---@param ecs table ECS instance
---@param camera table Camera instance
---@return CameraUpdateSystem
function CameraUpdateSystem:init(ecs, camera)
    Systems.UpdateSystem.init(self, ecs)

    if not camera then
        error("Camera must be provided to CameraUpdateSystem")
    end

    self.camera = camera
    return self
end

---@param dt number Delta time (unused for instant camera movement)
function CameraUpdateSystem:run(_)
    followTarget(self.camera, self.ecs)
end


---@class CameraSetupSystem : UpdateSystem
---@field ecs table ECS instance
---@field camera table Camera instance
---@field target table|nil Target entity to follow
local CameraSetupSystem = setmetatable({}, {__index = Systems.SetupSystem})
CameraSetupSystem.__index = CameraSetupSystem

---@return CameraSetupSystem
function CameraSetupSystem.new()
    local system = Systems.SetupSystem.new()
    setmetatable(system, CameraSetupSystem)
    return system
end


---@param ecs table ECS instance
---@param camera table Camera instance
---@return CameraUpdateSystem
function CameraSetupSystem:init(ecs, camera, targetEntity)
    Systems.UpdateSystem.init(self, ecs)

    if not camera then
        error("Camera must be provided to CameraUpdateSystem")
    end

    self.camera = camera
    return self
end

function CameraSetupSystem:run()
    followTarget(self.camera, self.ecs)
end


local CameraSystems = {
    CameraSetupSystem = CameraSetupSystem,
    CameraUpdateSystem = CameraUpdateSystem
}

return CameraSystems
