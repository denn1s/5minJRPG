-- ECS/core/grid_sync_system.lua
local Systems = require("ECS.systems")
local SceneManager = require("ECS.scene_manager")

---@class GridSyncSystem : UpdateSystem
---@field ecs table ECS instance
local GridSyncSystem = setmetatable({}, {__index = Systems.UpdateSystem})
GridSyncSystem.__index = GridSyncSystem

---@return GridSyncSystem
function GridSyncSystem.new()
  local system = Systems.UpdateSystem.new()
  setmetatable(system, GridSyncSystem)
  return system
end

---@param ecs table
---@return GridSyncSystem
function GridSyncSystem:init(ecs)
  Systems.UpdateSystem.init(self, ecs)
  return self
end

---@param dt number Delta time (unused in this system)
function GridSyncSystem:run(_)
  local world = SceneManager.activeScene.world

  if not world then return end

  -- Get all entities with transform component
  local entities = self.ecs:getEntitiesWithComponent("transform")

  for _, entity in ipairs(entities) do
    local transform = entity:getComponent("transform")

    -- Update grid coordinates based on pixel position
    -- This allows for smooth pixel movement while maintaining grid awareness
    transform.gridX, transform.gridY = world:pixelToGrid(transform.x, transform.y)
  end
end

return GridSyncSystem
