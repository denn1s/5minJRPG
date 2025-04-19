-- ECS/world_manager.lua
-- Singleton manager for world-related operations

local World = require("ECS.world")

---@class WorldManager
---@field instance WorldManager|nil Singleton instance
local WorldManager = {}
local instance = nil

-- Get the singleton instance
---@return WorldManager
function WorldManager.getInstance()
    if not instance then
        instance = {
            activeWorld = nil,
            worlds = {}
        }
        setmetatable(instance, { __index = WorldManager })
    end
    return instance
end

-- Create a new world and register it
---@param id string Unique identifier for the world
---@param gridWidth number Width in grid cells
---@param gridHeight number Height in grid cells
---@param gridSize? number Size of each grid cell in pixels
---@return World
function WorldManager:createWorld(id, gridWidth, gridHeight, gridSize)
    local world = World.new(gridWidth, gridHeight, gridSize)
    self.worlds[id] = world

    -- Set as active world if none exists
    if not self.activeWorld then
        self.activeWorld = world
    end

    return world
end

-- Set the active world
---@param worldOrId World|string Either a World object or world ID
---@return World|nil
function WorldManager:setActiveWorld(worldOrId)
    if type(worldOrId) == "string" then
        self.activeWorld = self.worlds[worldOrId]
    else
        self.activeWorld = worldOrId
    end
    return self.activeWorld
end

-- Get a world by ID
---@param id string
---@return World|nil
function WorldManager:getWorld(id)
    return self.worlds[id]
end

-- Get the active world
---@return World|nil
function WorldManager:getActiveWorld()
    return self.activeWorld
end

-- Convert grid coordinates to world pixel coordinates
---@param gridX number
---@param gridY number
---@param world? World Optional world object (uses active world if not provided)
---@return number, number
function WorldManager:gridToPixel(gridX, gridY, world)
    world = world or self.activeWorld
    if not world then return 0, 0 end

    return gridX * world.gridSize, gridY * world.gridSize
end

-- Convert world pixel coordinates to grid coordinates
---@param pixelX number
---@param pixelY number
---@param world? World Optional world object (uses active world if not provided)
---@return number, number
function WorldManager:pixelToGrid(pixelX, pixelY, world)
    world = world or self.activeWorld
    if not world then return 0, 0 end

    return math.floor(pixelX / world.gridSize), math.floor(pixelY / world.gridSize)
end

-- Check if a grid position is within world bounds
---@param gridX number
---@param gridY number
---@param world? World Optional world object (uses active world if not provided)
---@return boolean
function WorldManager:isGridPositionInBounds(gridX, gridY, world)
    world = world or self.activeWorld
    if not world then return false end

    return gridX >= 0 and gridX < world.gridWidth and
           gridY >= 0 and gridY < world.gridHeight
end

-- Check if a pixel position is within world bounds
---@param pixelX number
---@param pixelY number
---@param world? World Optional world object (uses active world if not provided)
---@return boolean
function WorldManager:isPixelPositionInBounds(pixelX, pixelY, world)
    world = world or self.activeWorld
    if not world then return false end

    return pixelX >= 0 and pixelX < world.pixelWidth and
           pixelY >= 0 and pixelY < world.pixelHeight
end

-- Update the world's grid size
---@param gridSize number
---@param world? World Optional world object (uses active world if not provided)
---@return World|nil
function WorldManager:setGridSize(gridSize, world)
    world = world or self.activeWorld
    if not world then return nil end

    world.gridSize = gridSize
    world.pixelWidth = world.gridWidth * gridSize
    world.pixelHeight = world.gridHeight * gridSize

    return world
end

return WorldManager
