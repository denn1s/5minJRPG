-- ECS/components.lua
-- Common component definitions

local Components = {}

---@class TransformComponent
---@field name string Always "transform"
---@field gridX number Grid X-coordinate
---@field gridY number Grid Y-coordinate
---@field x number Pixel X-coordinate
---@field y number Pixel Y-coordinate

-- Transform component (position, rotation, scale)
---@param x? number Position in pixels
---@param y? number Position in pixels
---@return TransformComponent
function Components.transform(x, y)
    return {
        name = "transform",
        gridX = 0,
        gridY = 0,
        x = x,
        y = y
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
---@return TextureComponent
function Components.texture(path)
    return {
        name = "texture",
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
---@param texturePath string Path to the texture and its cache index
---@param width? number Width of a single sprite in pixels
---@param height? number Height of a single sprite in pixels
---@param xIndex? number Initial sprite x-index in the sheet to use when rendering
---@param yIndex? number Initial sprite y-index in the sheet
---@return SpriteComponent
function Components.sprite(texturePath, width, height, xIndex, yIndex)
    return {
        name = "sprite",
        texturePath = texturePath,
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

---@class ColliderComponent
---@field name string Always "collider"
---@field width number Width of the collider in pixels
---@field height number Height of the collider in pixels
---@field offsetX number X offset from the entity's transform position
---@field offsetY number Y offset from the entity's transform position
---@field debug boolean Whether to render this collider for debugging

-- Collider component for physics and interaction detection
---@param width? number Width of the collider
---@param height? number Height of the collider
---@param offsetX? number X offset from entity position
---@param offsetY? number Y offset from entity position
---@param debug? boolean Whether to render the collider for debugging
---@return ColliderComponent
function Components.collider(width, height, offsetX, offsetY, debug)
    return {
        name = "collider",
        width = width or 16,
        height = height or 16,
        offsetX = offsetX or 0,
        offsetY = offsetY or 0,
        debug = debug or false
    }
end

return Components
