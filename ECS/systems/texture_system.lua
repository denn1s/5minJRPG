-- ECS/systems/texture_system.lua
-- System for loading sprite sheets and managing sprite data

local Systems = require("ECS.systems")

---@class TextureSystem : SetupSystem
---@field ecs table ECS instance
---@field textureCache table<string, table> Cache of loaded sprites by path
---@field colorMap table<string, number> Mapping of RGB values to color indices
local TextureSystem = setmetatable({}, {__index = Systems.SetupSystem})
TextureSystem.__index = TextureSystem

---@return TextureSystem
function TextureSystem.new()
    local system = Systems.SetupSystem.new()
    setmetatable(system, TextureSystem)
    
    -- Sprite cache to avoid reloading the same sprite sheet
    system.textureCache = {}
    
    -- Default color mapping for sprites
    -- Format: "r,g,b" -> colorIndex
    system.colorMap = {
        ["0,0,0"] = 1,         -- Black -> Darkest (index 1)
        ["51,44,80"] = 2,      -- Dark blue-purple -> Dark (index 2)
        ["70,135,143"] = 3,    -- Teal -> Light (index 3)
        ["226,243,228"] = 4    -- Off-white -> Lightest (index 4)
    }
    
    return system
end

---@param ecs table
---@param colorMap? table<string, number> Optional custom color mapping
---@return TextureSystem
function TextureSystem:init(ecs, colorMap)
    Systems.SetupSystem.init(self, ecs)
    
    -- Override default colorMap if provided
    if colorMap then
        self.colorMap = colorMap
    end
    
    return self
end

-- Generate a cache key string from an RGB color
---@param r number Red component (0-255)
---@param g number Green component (0-255)
---@param b number Blue component (0-255)
---@return string
function TextureSystem:getColorKey(r, g, b)
    return string.format("%d,%d,%d", r, g, b)
end

-- Load a texture and convert to the indexed color format
---@param path string
---@return table spriteData
---@return number sheetWidth
---@return number sheetHeight
function TextureSystem:loadTexture(path)
    -- Check if the sprite is already in the cache
    if self.textureCache[path] then
        return self.textureCache[path].data, 
               self.textureCache[path].width, 
               self.textureCache[path].height
    end
    
    -- Load the image using Love2D
    local success, imageData
    success, imageData = pcall(function()
        return love.image.newImageData(path)
    end)
    
    if not success then
        print("Failed to load sprite: " .. path)
        return {}, 0, 0
    end
    
    -- Get the image dimensions
    local sheetWidth = imageData:getWidth()
    local sheetHeight = imageData:getHeight()
    
    -- Convert the image to our color-indexed format
    local spriteData = {}
    
    -- For each pixel in the image
    for y = 0, sheetHeight - 1 do
        spriteData[y + 1] = {}
        for x = 0, sheetWidth - 1 do
            -- Get the pixel color from the image
            local r, g, b, a = imageData:getPixel(x, y)
            
            -- Skip transparent pixels
            if a > 0 then
                -- Convert to our color map
                local colorKey = self:getColorKey(math.floor(r * 255), math.floor(g * 255), math.floor(b * 255))
                local colorIndex = self.colorMap[colorKey]
                
                -- If the color isn't in our map, it's transparent
                spriteData[y + 1][x + 1] = colorIndex or 0
            else
                -- Transparent
                spriteData[y + 1][x + 1] = 0
            end
        end
    end
    
    -- Store in cache
    self.textureCache[path] = {
        data = spriteData,
        width = sheetWidth,
        height = sheetHeight
    }
    
    print("Loaded sprite: " .. path .. " (" .. sheetWidth .. "x" .. sheetHeight .. ")")
    
    return spriteData, sheetWidth, sheetHeight
end

-- Run system to load all textures
function TextureSystem:run()
    -- Get all entities with sprite components
    local entities = self.ecs:getEntitiesWithComponent("texture")
    
    for _, entity in ipairs(entities) do
        local tex = entity:getComponent("texture")
        
        if tex and not tex.loaded then
            -- Load the sprite sheet
            local sheetData, sheetWidth, sheetHeight = self:loadTexture(tex.path)
            
            -- Update the sprite component with sheet info
            tex.width = sheetWidth
            tex.height = sheetHeight
            
            -- Store the full sprite sheet data
            tex.data = sheetData

            tex.loaded = true
        end
    end
end

return TextureSystem
