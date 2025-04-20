-- ECS/core/collider_system.lua
-- System to prevent player from moving into non-walkable tiles,
-- with pixel-level collision checks and smart push behavior.

local Systems = require("ECS.systems")
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
    return self
end

-- Helper: math.sign function (Lua 5.3+)
local function math_sign(x)
    if x > 0 then return 1 elseif x < 0 then return -1 else return 0 end
end

math.sign = math.sign or math_sign

-- Helper: Check if a pixel position is walkable
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
        return true
    end

    local tileX = math.floor(x / gridSize)
    local tileY = math.floor(y / gridSize)

    if tileX < 0 or tileY < 0 or tileX >= collisionLayer.__cWid or tileY >= collisionLayer.__cHei then
        return false
    end

    local index = tileY * collisionLayer.__cWid + tileX + 1
    local tileValue = collisionLayer.intGridCsv[index]

    local walkable = tileValue == 1
    if not walkable then
    end
    return walkable
end

-- Helper: Check collision and return colliding pixels (relative to collider)
local function checkCollisionAt(self, level, newX, newY, collider)
    local newStartX = newX + collider.offsetX
    local newStartY = newY + collider.offsetY
    local newEndX = newStartX + collider.width
    local newEndY = newStartY + collider.height

    local collidingPixels = {}

    for y = newStartY, newEndY - 1 do
        for x = newStartX, newEndX - 1 do
            if not self:isWalkablePixel(level, x, y) then
                -- Store pixel relative to collider top-left
                table.insert(collidingPixels, {x = x - newStartX, y = y - newStartY})
            end
        end
    end

    return #collidingPixels > 0, collidingPixels
end

local function decidePushDirection(collidingPixel, velocity, collider)
    local cx, cy = collidingPixel.x, collidingPixel.y
    local w, h = collider.width, collider.height

    local left = 0
    local right = w - 1
    local top = 0
    local bottom = h - 1

    local dx = velocity.dx
    local dy = velocity.dy

    local pushX, pushY

    if cx == left and cy == top then
        if dx ~= 0 then
            pushX, pushY = 0, 1 -- push down
        elseif dy ~= 0 then
            pushX, pushY = 1, 0 -- push right
        end
    elseif cx == right and cy == top then
        if dx ~= 0 then
            pushX, pushY = 0, 1 -- push down
        elseif dy ~= 0 then
            pushX, pushY = -1, 0 -- push left
        end
    elseif cx == left and cy == bottom then
        if dx ~= 0 then
            pushX, pushY = 0, -1 -- push up
        elseif dy ~= 0 then
            pushX, pushY = -1, 0 -- push left
        end
    else
        -- Side cases
        if dx ~= 0 then
            pushX, pushY = -math.sign(dx), 0
        elseif dy ~= 0 then
            pushX, pushY = 0, -math.sign(dy)
        else
            pushX, pushY = 0, 0
        end
    end
    return pushX or 0, pushY or 0
end


function ColliderSystem:run(dt)
    local players = self.ecs:getEntitiesWithComponent("player")
    if #players == 0 then
        return
    end
    local player = players[1]

    local transform = player:getComponent("transform")
    local velocity = player:getComponent("velocity")
    local collider = player:getComponent("collider")

    if not (transform and velocity and collider) then
        return
    end

    local level = self.ldtk:getLevel(self.currentLevel)
    if not level then
        return
    end

    -- Check if player is fully inside walkable tiles at current position
    local startX = transform.x + collider.offsetX
    local startY = transform.y + collider.offsetY
    local endX = startX + collider.width
    local endY = startY + collider.height

    for y = startY, endY - 1 do
        for x = startX, endX - 1 do
            if not self:isWalkablePixel(level, x, y) then
                return
            end
        end
    end

    local originalDx = velocity.dx
    local originalDy = velocity.dy

    -- Horizontal movement only
    local newX = transform.x + originalDx * dt
    local newY = transform.y
    local collisionX, collidingPixelsX = false, {}
    if originalDx ~= 0 then
        collisionX, collidingPixelsX = checkCollisionAt(self, level, newX, newY, collider)
        if collisionX then
            if #collidingPixelsX == 1 then
                local pushX, pushY = decidePushDirection(collidingPixelsX[1], velocity, collider)
                velocity.dx = pushX * (1 / dt)
                velocity.dy = pushY * (1 / dt)
            else
                velocity.dx = 0
            end
        end
    end

    -- Vertical movement only
    newX = transform.x
    newY = transform.y + originalDy * dt
    local collisionY, collidingPixelsY = false, {}
    if originalDy ~= 0 then
        collisionY, collidingPixelsY = checkCollisionAt(self, level, newX, newY, collider)
        if collisionY then
            if #collidingPixelsY == 1 then
                local pushX, pushY = decidePushDirection(collidingPixelsY[1], velocity, collider)
                velocity.dx = pushX * (1 / dt)
                velocity.dy = pushY * (1 / dt)
            else
                velocity.dy = 0
            end
        end
    end
end

return ColliderSystem

