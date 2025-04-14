-- ECS/world.lua
-- World system for the ECS

---@class World
---@field width number Width of the world
---@field height number Height of the world
---@field properties table<string, any> Additional world properties
local World = {}
World.__index = World

---@param width number Width of the world
---@param height number Height of the world
---@param properties? table<string, any> Additional world properties
---@return World
function World.new(width, height, properties)
    local world = {
        width = width,
        height = height,
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

-- Check if a position is within world bounds
---@param x number
---@param y number
---@return boolean
function World:isInBounds(x, y)
    return x >= 0 and x < self.width and
           y >= 0 and y < self.height
end

return World
