-- ECS/components.lua
-- Common component definitions

local Components = {}

---@class TransformComponent
---@field name string Always "transform"
---@field x number X-coordinate
---@field y number Y-coordinate
---@field rotation number Rotation in radians
---@field scale number Scale factor

-- Transform component (position, rotation, scale)
---@param x? number
---@param y? number
---@param rotation? number
---@param scale? number
---@return TransformComponent
function Components.transform(x, y, rotation, scale)
    return {
        name = "transform",
        x = x or 0,
        y = y or 0,
        rotation = rotation or 0,
        scale = scale or 1
    }
end

---@class VelocityComponent
---@field name string Always "velocity"
---@field dx number X velocity
---@field dy number Y velocity

-- Velocity component
---@param dx? number
---@param dy? number
---@return VelocityComponent
function Components.velocity(dx, dy)
    return {
        name = "velocity",
        dx = dx or 0,
        dy = dy or 0
    }
end

---@class SpriteComponent
---@field name string Always "sprite"
---@field data table Array of pixel data
---@field width number Width of sprite
---@field height number Height of sprite

-- Sprite component
---@param data? table
---@param width? number
---@param height? number
---@return SpriteComponent
function Components.sprite(data, width, height)
    return {
        name = "sprite",
        data = data or {},  -- Array of pixel data
        width = width or 1,
        height = height or 1
    }
end

---@class KeyMap
---@field up string
---@field down string
---@field left string
---@field right string
---@field action string

---@class InputComponent
---@field name string Always "input"
---@field keyMap KeyMap Key mapping configuration

-- Input component (marks entity as controlled by player)
---@param keyMap? KeyMap
---@return InputComponent
function Components.input(keyMap)
    return {
        name = "input",
        keyMap = keyMap or {
            up = "up",
            down = "down",
            left = "left",
            right = "right",
            action = "z"
        }
    }
end

---@class CollisionComponent
---@field name string Always "collision"
---@field radius number Collision radius
---@field solid boolean Whether the entity is solid

-- Collision component
---@param radius? number
---@return CollisionComponent
function Components.collision(radius)
    return {
        name = "collision",
        radius = radius or 1,
        solid = true
    }
end

return Components
