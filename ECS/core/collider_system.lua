local Systems = require("ECS.systems")
local Components = require("ECS.components")
local LDtkManager = require("ECS.ldtk.ldtk_manager")

local ColliderSystem = setmetatable({}, {__index = Systems.UpdateSystem})
ColliderSystem.__index = ColliderSystem

function ColliderSystem.new()
  local system = Systems.UpdateSystem.new()
  setmetatable(system, ColliderSystem)
  return system
end

function ColliderSystem:init(ecs, currentLevel)
  Systems.UpdateSystem.init(self, ecs)
  self.currentLevel = currentLevel
  self.ldtk = LDtkManager.getInstance()
  print("[ColliderSystem] Initializing for level: " .. currentLevel)
  return self
end

function ColliderSystem:isWalkablePixel(level, x, y)
    local gridSize = self.ldtk:getGridSize()
    local collisionLayer = nil

    for _, layer in ipairs(level.layerInstances) do
        if layer.__type == "IntGrid" and layer.__identifier == "Collision" then
            collisionLayer = layer
            break
        end
    end

    if not collisionLayer then
        print("[ColliderSystem] No Collision layer found, assuming walkable")
        return true
    end

    local tileX = math.floor(x / gridSize)
    local tileY = math.floor(y / gridSize)

    if tileX < 0 or tileY < 0 or tileX >= collisionLayer.__cWid or tileY >= collisionLayer.__cHei then
        print(string.format("[ColliderSystem] Pixel (%.2f, %.2f) out of bounds", x, y))
        return false
    end

    local index = tileY * collisionLayer.__cWid + tileX + 1
    local tileValue = collisionLayer.intGridCsv[index]

    local walkable = tileValue == 1
    if not walkable then
        print(string.format("[ColliderSystem] Pixel (%.2f, %.2f) on non-walkable tile (value %d)", x, y, tileValue))
    end
    return walkable
end

function ColliderSystem:run(dt)
    local players = self.ecs:getEntitiesWithComponent("player")
    if #players == 0 then
        print("[ColliderSystem] No player entity found")
        return
    end
    local player = players[1]

    local transform = player:getComponent("transform")
    local velocity = player:getComponent("velocity")
    local collider = player:getComponent("collider")

    if not (transform and velocity and collider) then
        print("[ColliderSystem] Missing required components on player")
        return
    end

    local level = self.ldtk:getLevel(self.currentLevel)
    if not level then
        print("[ColliderSystem] Current level not found")
        return
    end

    -- Check if player is fully inside walkable tiles at current position
    local startX = transform.x + collider.offsetX
    local startY = transform.y + collider.offsetY
    local endX = startX + collider.width
    local endY = startY + collider.height

    print("[ColliderSystem] Checking if player is fully inside walkable tiles at current position")

    for y = startY, endY - 1 do
        for x = startX, endX - 1 do
            if not self:isWalkablePixel(level, x, y) then
                print("[ColliderSystem] Player is partially or fully outside walkable area, skipping collision check")
                return
            end
        end
    end

    print("[ColliderSystem] Player fully inside walkable area, proceeding with collision check")

    local originalDx = velocity.dx
    local originalDy = velocity.dy

    -- Helper function to check collision for proposed position
    local function checkCollisionAt(newX, newY)
        local newStartX = newX + collider.offsetX
        local newStartY = newY + collider.offsetY
        local newEndX = newStartX + collider.width
        local newEndY = newStartY + collider.height

        for y = newStartY, newEndY - 1 do
            for x = newStartX, newEndX - 1 do
                if not self:isWalkablePixel(level, x, y) then
                    return true -- collision detected
                end
            end
        end
        return false -- no collision
    end

    -- Check horizontal movement only
    local newX = transform.x + originalDx * dt
    local newY = transform.y
    local collisionX = false
    if originalDx ~= 0 then
        print(string.format("[ColliderSystem] Checking horizontal movement to x=%.2f", newX))
        collisionX = checkCollisionAt(newX, newY)
        if collisionX then
            print("[ColliderSystem] Horizontal collision detected, zeroing dx")
            velocity.dx = 0
        end
    end

    -- Check vertical movement only
    newX = transform.x
    newY = transform.y + originalDy * dt
    local collisionY = false
    if originalDy ~= 0 then
        print(string.format("[ColliderSystem] Checking vertical movement to y=%.2f", newY))
        collisionY = checkCollisionAt(newX, newY)
        if collisionY then
            print("[ColliderSystem] Vertical collision detected, zeroing dy")
            velocity.dy = 0
        end
    end

    -- If no collision in either direction, keep original velocity
    if not collisionX and not collisionY then
        print("[ColliderSystem] No collision detected, velocity remains unchanged")
    end
end

return ColliderSystem

