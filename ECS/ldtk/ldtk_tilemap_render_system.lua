-- ECS/ldtk/ldtk_tilemap_render_system.lua
-- System for rendering LDtk tilemaps using the existing color palette

local Systems = require("ECS.systems")
local TextureManager = require("ECS.texture_manager")
local LDtkManager = require("ECS.ldtk.ldtk_manager")

---@class LDtkTilemapRenderSystem : RenderSystem
---@field ecs table ECS instance
local LDtkTilemapRenderSystem = setmetatable({}, {__index = Systems.RenderSystem})
LDtkTilemapRenderSystem.__index = LDtkTilemapRenderSystem

---@return LDtkTilemapRenderSystem
function LDtkTilemapRenderSystem.new()
    local system = Systems.RenderSystem.new()
    setmetatable(system, LDtkTilemapRenderSystem)
    return system
end

---@param ecs table
---@param currentLevel string Current level identifier as a string
---@return LDtkTilemapRenderSystem
function LDtkTilemapRenderSystem:init(ecs, currentLevel)
    Systems.RenderSystem.init(self, ecs)
    self.currentLevel = currentLevel
    self.ldtk = LDtkManager.getInstance()
    print("[LDtkRenderSystem] Initializing for level: " .. currentLevel)
    return self
end

---@param renderer table
function LDtkTilemapRenderSystem:run(renderer)
    local level = self.ldtk:getLevel(self.currentLevel)
    if not level then
        print("[LDtkRenderSystem] ERROR: Level not found: " .. self.currentLevel)
        return
    end

    if not level.layerInstances then
        print("[LDtkRenderSystem] No layers to render in level: " .. self.currentLevel)
        return
    end

    for _, layer in ipairs(level.layerInstances) do
        if layer.__type == "Tiles" and layer.gridTiles and #layer.gridTiles > 0 then
            self:renderLayer(renderer, layer)
        end
    end
end

-- Render a specific layer
---@param renderer table
---@param layer table
function LDtkTilemapRenderSystem:renderLayer(renderer, layer)
    local camera = renderer.camera
    if not camera then
        print("[LDtkRenderSystem] ERROR: No camera available for rendering")
        return
    end

    local gridSize = self.ldtk:getGridSize()
    local tiles = layer.gridTiles
    local texturePath = self.ldtk:getTilesetTexturePath(layer)
    local textureData = TextureManager.getTexture(texturePath)

    if not textureData or not textureData[1] then
        print("[LDtkRenderSystem] WARNING: Texture not loaded for path: " .. texturePath)
        return
    end

    for _, tile in ipairs(tiles) do
        local px = tile.px[1]
        local py = tile.px[2]

        if camera:isRectVisible(px, py, gridSize, gridSize) then
            local srcX = math.floor(tile.src[1] / gridSize)
            local srcY = math.floor(tile.src[2] / gridSize)
            self:renderTile(renderer, textureData, px, py, gridSize, srcX, srcY)
        end
    end
end

-- Render a single tile
---@param renderer table
---@param textureData table
---@param px number Pixel x position in world
---@param py number Pixel y position in world
---@param gridSize number Size of the tile grid
---@param xIndex number X index in the tileset
---@param yIndex number Y index in the tileset
function LDtkTilemapRenderSystem:renderTile(renderer, textureData, px, py, gridSize, xIndex, yIndex)
    local screenX, screenY = renderer:worldToScreen(px, py)
    local startX = xIndex * gridSize + 1
    local startY = yIndex * gridSize + 1

    for dy = 0, gridSize - 1 do
        local srcY = startY + dy
        if textureData[srcY] then
            for dx = 0, gridSize - 1 do
                local srcX = startX + dx
                local colorIndex = textureData[srcY][srcX] or 0
                if colorIndex > 0 then
                    love.graphics.setColor(renderer.COLORS[colorIndex])
                    love.graphics.points(math.floor(screenX + dx), math.floor(screenY + dy))
                end
            end
        end
    end
end

return LDtkTilemapRenderSystem

