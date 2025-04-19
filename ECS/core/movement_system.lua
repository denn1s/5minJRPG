-- ECS/core/movement_system.lua
local Systems = require("ECS.systems")

---@class MovementSystem : UpdateSystem
---@field ecs table ECS instance
local MovementSystem = setmetatable({}, {__index = Systems.UpdateSystem})
MovementSystem.__index = MovementSystem

---@return MovementSystem
function MovementSystem.new()
  local system = Systems.UpdateSystem.new()
  setmetatable(system, MovementSystem)
  return system
end

---@param ecs table
---@return MovementSystem
function MovementSystem:init(ecs)
  Systems.UpdateSystem.init(self, ecs)
  return self
end

---@param dt number Delta time
function MovementSystem:run(dt)
  -- Get all entities with both transform and velocity components
  local entities = self.ecs:getEntitiesWithComponent("velocity")

  for _, entity in ipairs(entities) do
    local transform = entity:getComponent("transform")
    local velocity = entity:getComponent("velocity")

    if transform and velocity then
      -- Update moving state
      velocity.moving = velocity.dx ~= 0 or velocity.dy ~= 0

      -- Only update position if actually moving
      if velocity.moving then
        -- Update position based on velocity
        transform.x = transform.x + velocity.dx * dt
        transform.y = transform.y + velocity.dy * dt
      end
    end
  end
end

return MovementSystem
