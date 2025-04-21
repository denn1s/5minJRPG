-- ECS/world.lua
-- World data storage and management class for the ECS

---@class World
---@field gridWidth number Width of the world in grid cells
---@field gridHeight number Height of the world in grid cells
---@field pixelWidth number Width of the world in pixels
---@field pixelHeight number Height of the world in pixels
---@field gridSize number Size of each grid cell in pixels
---@field properties table<string, any> Additional world properties
local World = {}
World.__index = World

---@param gridWidth number Width of the world in grid cells
---@param gridHeight number Height of the world in grid cells
---@param gridSize? number Size of each grid cell in pixels
---@param properties? table<string, any> Additional world properties
---@return World
function World.new(gridWidth, gridHeight, gridSize, properties)
    gridSize = gridSize or 8

    local world = {
        gridWidth = gridWidth,
        gridHeight = gridHeight,
        gridSize = gridSize,
        pixelWidth = gridWidth * gridSize,
        pixelHeight = gridHeight * gridSize,
        properties = properties or {}
    }
    setmetatable(world, World)
    return world
end

-- Set a property value
---@param key string
---@param value any
---@return World
function World:setProperty(key, value)
    self.properties[key] = value
    return self
end

-- Get a property value
---@param key string
---@param default? any Default value if property doesn't exist
---@return any
function World:getProperty(key, default)
    return self.properties[key] ~= nil and self.properties[key] or default
end

-- Set the size of the world in grid units
---@param gridWidth number
---@param gridHeight number
---@return World
function World:setSize(gridWidth, gridHeight)
    self.gridWidth = gridWidth
    self.gridHeight = gridHeight
    self.pixelWidth = gridWidth * self.gridSize
    self.pixelHeight = gridHeight * self.gridSize
    return self
end

-- Convert grid coordinates to world pixel coordinates
---@param gridX number
---@param gridY number
---@return number, number
function World:gridToPixel(gridX, gridY)
    return gridX * self.gridSize, gridY * self.gridSize
end

-- Convert world pixel coordinates to grid coordinates
---@param pixelX number
---@param pixelY number
---@return number, number
function World:pixelToGrid(pixelX, pixelY)
    return math.floor(pixelX / self.gridSize), math.floor(pixelY / self.gridSize)
end

-- Check if a grid position is within world bounds
---@param gridX number
---@param gridY number
---@return boolean
function World:isGridPositionInBounds(gridX, gridY)
    return gridX >= 0 and gridX < self.gridWidth and
           gridY >= 0 and gridY < self.gridHeight
end

-- Check if a pixel position is within world bounds
---@param pixelX number
---@param pixelY number
---@return boolean
function World:isPixelPositionInBounds(pixelX, pixelY)
    return pixelX >= 0 and pixelX < self.pixelWidth and
           pixelY >= 0 and pixelY < self.pixelHeight
end

-- Update the world's grid size
---@param gridSize number
---@return World
function World:setGridSize(gridSize)
    self.gridSize = gridSize
    self.pixelWidth = self.gridWidth * gridSize
    self.pixelHeight = self.gridHeight * gridSize
    return self
end

return World

