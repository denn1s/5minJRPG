-- ECS/ldtk/ldtk_tilemap_render_system.lua
-- System for rendering LDtk tilemaps using the existing color palette

local Systems = require("ECS.systems")
local TextureManager = require("ECS.texture_manager")

---@class LDtkTilemapRenderSystem : RenderSystem
---@field ecs table ECS instance
---@field ldtkData table LDtk parsed data
---@field currentLevel string Current level identifier
---@field tileCache table<string, table> Cache of rendered tiles
---@field levelLayersCache table Cache of level layers for faster rendering
local LDtkTilemapRenderSystem = setmetatable({}, {__index = Systems.RenderSystem})
LDtkTilemapRenderSystem.__index = LDtkTilemapRenderSystem

---@return LDtkTilemapRenderSystem
function LDtkTilemapRenderSystem.new()
    local system = Systems.RenderSystem.new()
    setmetatable(system, LDtkTilemapRenderSystem)
    system.tileCache = {}
    system.levelLayersCache = {}
    return system
end

---@param ecs table
---@param ldtkData table LDtk parsed data
---@param currentLevel string Current level identifier
---@return LDtkTilemapRenderSystem
function LDtkTilemapRenderSystem:init(ecs, ldtkData, currentLevel)
    Systems.RenderSystem.init(self, ecs)
    self.ldtkData = ldtkData
    self.currentLevel = currentLevel
    
    -- Initialize the tile cache
    self:initTileCache()
    
    return self
end

-- Initialize the tile cache and prepare level layers for rendering
function LDtkTilemapRenderSystem:initTileCache()
    if not self.ldtkData or not self.currentLevel then
        print("LDtkTilemapRenderSystem: No LDtk data or current level")
        return
    end
    
    -- Find the current level data
    local levelData = nil
    for _, level in ipairs(self.ldtkData.levels) do
        if level.identifier == self.currentLevel then
            levelData = level
            break
        end
    end
    
    if not levelData then
        print("LDtkTilemapRenderSystem: Level not found: " .. self.currentLevel)
        return
    end
    
    -- Process tilesets to build a cache of tile sources
    self:processTilesets()
    
    -- Cache the layers for faster rendering
    self:cacheLayersForLevel(levelData)
    
    print("LDtkTilemapRenderSystem: Initialized for level " .. self.currentLevel)
end

-- Process tilesets to build a cache of tile sources
function LDtkTilemapRenderSystem:processTilesets()
    if not self.ldtkData or not self.ldtkData.defs or not self.ldtkData.defs.tilesets then
        return
    end
    
    for _, tileset in ipairs(self.ldtkData.defs.tilesets) do
        local tilesetId = tileset.uid
        local tilesetGridSize = tileset.tileGridSize
        local tilesetPath = tileset.relPath
        
        print("Processing tileset: " .. tileset.identifier .. " (Grid size: " .. tilesetGridSize .. ")")
        
        -- Store tileset info in our cache for later use
        self.tileCache[tilesetId] = {
            path = tilesetPath,
            gridSize = tilesetGridSize,
            width = tileset.__cWid,
            height = tileset.__cHei,
            identifier = tileset.identifier,
            tiles = {}
        }
    end
end

-- Cache the layers for a specific level for faster rendering
---@param levelData table Level data from LDtk
function LDtkTilemapRenderSystem:cacheLayersForLevel(levelData)
    if not levelData or not levelData.layerInstances then
        return
    end
    
    -- Clear existing cache for this level
    self.levelLayersCache = {}
    
    -- Process each layer from bottom to top
    for i = #levelData.layerInstances, 1, -1 do
        local layer = levelData.layerInstances[i]
        local layerId = layer.__identifier
        local layerType = layer.__type
        
        if layerType == "Tiles" then
            self:cacheTilesLayer(layer)
        end
    end
    
    print("LDtkTilemapRenderSystem: Cached " .. #self.levelLayersCache .. " layers for level " .. levelData.identifier)
end

-- Cache a Tiles layer for rendering
---@param layer table Layer instance data
function LDtkTilemapRenderSystem:cacheTilesLayer(layer)
    if not layer or not layer.gridTiles or #layer.gridTiles == 0 then
        return
    end
    
    local tilesetDefUid = layer.__tilesetDefUid
    if not tilesetDefUid or not self.tileCache[tilesetDefUid] then
        print("LDtkTilemapRenderSystem: Tileset not found for layer: " .. layer.__identifier)
        return
    end
    
    local layerCache = {
        identifier = layer.__identifier,
        tilesetUid = tilesetDefUid,
        gridSize = layer.__gridSize,
        tiles = layer.gridTiles,
        tilesetPath = self.tileCache[tilesetDefUid].path,
        opacity = layer.__opacity or 1.0
    }
    
    table.insert(self.levelLayersCache, layerCache)
    
    print("LDtkTilemapRenderSystem: Cached layer " .. layer.__identifier .. 
          " with " .. #layer.gridTiles .. " tiles using tileset " .. 
          self.tileCache[tilesetDefUid].identifier)
end

-- Get color index from LDtk color
---@param r number Red component (0-255)
---@param g number Green component (0-255)
---@param b number Blue component (0-255)
---@return number colorIndex Index in our color palette (1-4)
function LDtkTilemapRenderSystem:getColorIndex(r, g, b)
    -- Convert RGB to our game's color palette index
    local colorKey = string.format("%d,%d,%d", r, g, b)
    local colorMap = TextureManager.getInstance().colorMap
    
    -- Try to find an exact match
    local colorIndex = colorMap[colorKey]
    if colorIndex then
        return colorIndex
    end
    
    -- If no exact match, find the closest color
    local bestIndex = 1 -- Default to darkest color
    local bestDistance = 999999
    
    for keyStr, index in pairs(colorMap) do
        local kr, kg, kb = keyStr:match("(%d+),(%d+),(%d+)")
        kr, kg, kb = tonumber(kr), tonumber(kg), tonumber(kb)
        
        -- Calculate color distance (simple Euclidean distance)
        local distance = math.sqrt((r - kr)^2 + (g - kg)^2 + (b - kb)^2)
        
        if distance < bestDistance then
            bestDistance = distance
            bestIndex = index
        end
    end
    
    return bestIndex
end

---@param renderer table
function LDtkTilemapRenderSystem:run(renderer)
    -- Render all cached layers
    for _, layerCache in ipairs(self.levelLayersCache) do
        self:renderLayer(renderer, layerCache)
    end
end

-- Render a specific layer
---@param renderer table
---@param layerCache table Cached layer data
function LDtkTilemapRenderSystem:renderLayer(renderer, layerCache)
    local tilesetCache = self.tileCache[layerCache.tilesetUid]
    if not tilesetCache then
        return
    end
    
    -- Get the camera to check if tiles are visible
    local camera = renderer.camera
    if not camera then
        return
    end
    
    for _, tile in ipairs(layerCache.tiles) do
        local px = tile.px[1]
        local py = tile.px[2]
        
        -- Check if the tile is visible in the camera view
        if camera:isRectVisible(px, py, layerCache.gridSize, layerCache.gridSize) then
            -- Get the tile source from the tileset
            local srcX = tile.src[1]
            local srcY = tile.src[2]
            local tileId = tile.t
            
            -- Draw the tile
            self:renderTile(renderer, tilesetCache, px, py, srcX, srcY, layerCache.gridSize, layerCache.opacity)
        end
    end
end

-- Render a single tile
---@param renderer table
---@param tilesetCache table Tileset cache data
---@param px number Pixel x position in world
---@param py number Pixel y position in world
---@param srcX number Source x position in tileset
---@param srcY number Source y position in tileset
---@param gridSize number Size of the tile grid
---@param opacity number Opacity of the layer (0-1)
function LDtkTilemapRenderSystem:renderTile(renderer, tilesetCache, px, py, srcX, srcY, gridSize, opacity)
    -- Choose a color for the tile based on its position in the tileset
    -- This is a simple approach that assigns colors based on the tile's position
    -- Creating a pattern effect
    
    -- Calculate a deterministic color based on source position
    local colorVariation = ((srcX/8) + (srcY/8)) % 4
    local colorIndex = math.floor(colorVariation) + 1
    
    -- Modify the color based on the tileset type to create different visual effects for different tilesets
    if tilesetCache.identifier == "Interior" then
        -- Interior tiles use lighter colors (3 and 4)
        colorIndex = (colorIndex % 2) + 3
    elseif tilesetCache.identifier == "Town" then
        -- Town tiles use a mix of colors (2 and 3)
        colorIndex = (colorIndex % 2) + 2
    elseif tilesetCache.identifier == "Dungeon" then
        -- Dungeon tiles use darker colors (1 and 2)
        colorIndex = (colorIndex % 2) + 1
    end
    
    -- Render a colored rectangle for the tile
    renderer:draw_rectangle(
        px,
        py,
        gridSize,
        gridSize,
        colorIndex,
        true  -- filled
    )
    
    -- Add a darker outline to show tile boundaries
    renderer:draw_rectangle(
        px,
        py,
        gridSize,
        gridSize,
        1,  -- darkest color
        false  -- not filled (outline)
    )
end

-- Set the current level to render
---@param levelIdentifier string Level identifier
function LDtkTilemapRenderSystem:setLevel(levelIdentifier)
    if self.currentLevel == levelIdentifier then
        return -- Already set to this level
    end
    
    self.currentLevel = levelIdentifier
    
    -- Reinitialize tile cache for the new level
    self:initTileCache()
end

return LDtkTilemapRenderSystem
