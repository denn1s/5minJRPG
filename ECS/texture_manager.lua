-- ECS/texture_manager.lua
-- Global texture manager for loading and caching game textures and tilesets
---@class TextureManager
---@field textureCache table<string, table> Cache of textures by path
---@field colorMap table<string, number>
---@field debugMode boolean
local TextureManager = {}

local instance = nil

---@return TextureManager
function TextureManager.getInstance()
    if not instance then
        instance = {
            textureCache = {},
            colorMap = {
                ["0,0,0"] = 1,
                ["51,44,80"] = 2,
                ["70,135,143"] = 3,
                ["226,243,228"] = 4
            },
            debugMode = true,
            instanceId = tostring(math.random(10000, 99999))
        }
        print("[TextureManager] Instance created with ID: " .. instance.instanceId)
    end
    return instance
end

function TextureManager.getColorKey(r, g, b)
    return string.format("%d,%d,%d", r, g, b)
end

function TextureManager.getTexture(path)
    local m = TextureManager.getInstance()
    local entry = m.textureCache[path]
    if entry then return entry.data, entry.width, entry.height end
    return nil, 0, 0
end

function TextureManager.loadTexture(path)
    local m = TextureManager.getInstance()
    if m.textureCache[path] then
        if m.debugMode then
            print("[TextureManager] Texture already in cache: " .. path)
        end
        return TextureManager.getTexture(path)
    end

    local ok, imageData = pcall(function() return love.image.newImageData(path) end)
    if not ok then
        print("[TextureManager] ERROR: Failed to load texture: " .. path)
        print("[TextureManager] Details: " .. tostring(imageData))
        return {}, 0, 0
    end

    local w, h = imageData:getWidth(), imageData:getHeight()
    local spriteData = {}
    for y = 0, h - 1 do
        spriteData[y + 1] = {}
        for x = 0, w - 1 do
            local r, g, b, a = imageData:getPixel(x, y)
            local key = TextureManager.getColorKey(math.floor(r * 255), math.floor(g * 255), math.floor(b * 255))
            spriteData[y + 1][x + 1] = (a > 0 and m.colorMap[key]) or 0
        end
    end

    m.textureCache[path] = { data = spriteData, width = w, height = h, loadTime = os.time() }
    if m.debugMode then print("[TextureManager] Loaded and cached: " .. path) end
    return spriteData, w, h
end

---@param textureData table
---@param textureWidth number
---@param textureHeight number
---@param gridSize number
---@param tileX number
---@param tileY number
---@return table
function TextureManager.extractTileData(textureData, textureWidth, textureHeight, gridSize, tileX, tileY)
    local pixels = {}
    local startX = tileX * gridSize + 1
    local startY = tileY * gridSize + 1
    for y = startY, math.min(startY + gridSize - 1, textureHeight) do
        local row = {}
        for x = startX, math.min(startX + gridSize - 1, textureWidth) do
            row[#row+1] = textureData[y] and textureData[y][x] or 0
        end
        pixels[#pixels+1] = row
    end
    return pixels
end

return TextureManager

