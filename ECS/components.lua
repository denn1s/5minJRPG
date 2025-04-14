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


---@class TextureComponent
---@field name string Always "texture"
---@field texturePath string Path to the texture, and also the cache index 
---@field width number Width of a single sprite in the sheet
---@field height number Height of a single sprite in the sheet
---@field data table Array of pixel data (loaded from spritesheet)
---@field loaded boolean Whether the sprite has been loaded

-- Sprite component with spritesheet support
---@param texturePath string Path to sprite sheet image
---@return SpriteComponent
function Components.texture(path)
    return {
        name = "sprite",
        path = path,
        width = 0, -- will be loaded by the texture system
        height = 0,
        data = {},
        loaded = false
    }
end

---@class SpriteComponent
---@field name string Always "sprite"
---@field texture string Path to sprite sheet image
---@field width number Width of a single sprite in the sheet
---@field height number Height of a single sprite in the sheet
---@field xIndex number Current sprite x-index in the sheet
---@field yIndex number Current sprite y-index in the sheet

-- Sprite component with spritesheet support
---@param texture string Path to the texture and its cache index
---@param width? number Width of a single sprite in pixels
---@param height? number Height of a single sprite in pixels
---@param xIndex? number Initial sprite x-index in the sheet to use when rendering
---@param yIndex? number Initial sprite y-index in the sheet
---@return SpriteComponent
function Components.sprite(texture, width, height, xIndex, yIndex)
    return {
        name = "sprite",
        texture = texture,
        width = width or 16,
        height = height or 16,
        xIndex = xIndex or 0,
        yIndex = yIndex or 0,
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
