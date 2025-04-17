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
---@field showTileBoundaries boolean Whether to show tile boundaries
---@field debugMode boolean Whether to print detailed debug information
---@field frameCounter number Counter for periodic stats logging
local LDtkTilemapRenderSystem = setmetatable({}, {__index = Systems.RenderSystem})
LDtkTilemapRenderSystem.__index = LDtkTilemapRenderSystem

---@return LDtkTilemapRenderSystem
function LDtkTilemapRenderSystem.new()
    local system = Systems.RenderSystem.new()
    setmetatable(system, LDtkTilemapRenderSystem)
    system.tileCache = {}
    system.levelLayersCache = {}
    system.showTileBoundaries = false  -- Set to true to debug tile boundaries
    system.debugMode = true            -- Enable detailed debug logging
    system.frameCounter = 0            -- For periodic logging
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
    
    print("[LDtkRenderSystem] Initializing for level: " .. currentLevel)
    
    -- Initialize the tile cache
    self:initTileCache()
    
    return self
end

-- Initialize the tile cache and prepare level layers for rendering
function LDtkTilemapRenderSystem:initTileCache()
    if not self.ldtkData or not self.currentLevel then
        print("[LDtkRenderSystem] ERROR: No LDtk data or current level")
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
        print("[LDtkRenderSystem] ERROR: Level not found: " .. self.currentLevel)
        return
    end
    
    print("[LDtkRenderSystem] Initializing tile cache for level: " .. self.currentLevel)
    
    -- Process tilesets to build a cache of tile sources
    self:processTilesets()
    
    -- Cache the layers for faster rendering
    self:cacheLayersForLevel(levelData)
    
    print("[LDtkRenderSystem] Initialization complete for level " .. self.currentLevel)
    print(string.format("[LDtkRenderSystem] Cached %d layers with tilesets", #self.levelLayersCache))
end

-- Process tilesets to build a cache of tile sources
function LDtkTilemapRenderSystem:processTilesets()
    if not self.ldtkData or not self.ldtkData.defs or not self.ldtkData.defs.tilesets then
        print("[LDtkRenderSystem] ERROR: No tileset definitions found")
        return
    end
    
    local tilesetCount = #self.ldtkData.defs.tilesets
    print("[LDtkRenderSystem] Processing " .. tilesetCount .. " tilesets")
    
    -- Debug output - check for UID type mismatches
    print("[LDtkRenderSystem] === UID TYPE CHECKS ===")
    
    -- Get all tilesets from TextureManager
    local manager = TextureManager.getInstance()
    for uid, tileset in pairs(manager.tilesetCache) do
        print(string.format("[LDtkRenderSystem] TextureManager UID %s (type: %s): %s", 
            tostring(uid), type(uid), tileset.identifier))
    end
    
    -- Compare with UIDs in LDtk data
    for _, tileset in ipairs(self.ldtkData.defs.tilesets) do
        print(string.format("[LDtkRenderSystem] LDtk UID %s (type: %s): %s", 
            tostring(tileset.uid), type(tileset.uid), tileset.identifier))
    end
    
    print("[LDtkRenderSystem] === END UID TYPE CHECKS ===")
    
    -- First, dump the TextureManager's tileset cache for debugging
    print("[LDtkRenderSystem] --- TextureManager Tileset Cache Status ---")
    if TextureManager.dumpTilesetDebugInfo then
        TextureManager.dumpTilesetDebugInfo()
    end
    
    for _, tileset in ipairs(self.ldtkData.defs.tilesets) do
        local tilesetId = tileset.uid
        local tilesetGridSize = tileset.tileGridSize
        local tilesetPath = tileset.relPath
        
        print(string.format("[LDtkRenderSystem] Processing tileset: %s (UID: %d, Grid size: %d, Path: %s)", 
              tileset.identifier, tilesetId, tilesetGridSize, tilesetPath))
        
        -- Store tileset info in our cache for later use
        self.tileCache[tilesetId] = {
            path = tilesetPath,
            gridSize = tilesetGridSize,
            width = tileset.__cWid,
            height = tileset.__cHei,
            identifier = tileset.identifier,
            tiles = {}
        }
        
        -- Try different ways to look up the tileset
        print("[LDtkRenderSystem] Attempting to get tileset data from TextureManager...")
        
        -- 1. Try by UID
        local cachedTileset = TextureManager.getTileset(tilesetId)
        if cachedTileset then
            print("[LDtkRenderSystem] SUCCESS: Found tileset by UID: " .. tilesetId)
            self.tileCache[tilesetId].textureData = cachedTileset.textureData
            goto continue
        else
            print("[LDtkRenderSystem] Failed to find tileset by UID: " .. tilesetId)
        end
        
        -- 2. Try by identifier
        cachedTileset = TextureManager.getTileset(tileset.identifier)
        if cachedTileset then
            print("[LDtkRenderSystem] SUCCESS: Found tileset by identifier: " .. tileset.identifier)
            self.tileCache[tilesetId].textureData = cachedTileset.textureData
            goto continue
        else
            print("[LDtkRenderSystem] Failed to find tileset by identifier: " .. tileset.identifier)
        end
        
        -- 3. Try by path
        cachedTileset = TextureManager.getTileset(tilesetPath)
        if cachedTileset then
            print("[LDtkRenderSystem] SUCCESS: Found tileset by path: " .. tilesetPath)
            self.tileCache[tilesetId].textureData = cachedTileset.textureData
            goto continue
        else
            print("[LDtkRenderSystem] Failed to find tileset by path: " .. tilesetPath)
        end
        
        -- If we get here, we couldn't find the tileset
        print("[LDtkRenderSystem] WARNING: Tileset not found in TextureManager: " .. tileset.identifier)
        print("[LDtkRenderSystem] Will use simplified rendering for this tileset")
        
        ::continue::
        
        -- Check if we successfully got the texture data
        if self.tileCache[tilesetId].textureData then
            print("[LDtkRenderSystem] Successfully loaded texture data for " .. tileset.identifier)
            if self.debugMode then
                local pixelCount = 0
                for y, row in pairs(self.tileCache[tilesetId].textureData) do
                    for x, pixel in pairs(row) do
                        if pixel > 0 then pixelCount = pixelCount + 1 end
                    end
                end
                print(string.format("[LDtkRenderSystem] Texture data contains %d visible pixels", pixelCount))
            end
        end
    end
end

-- Cache the layers for a specific level for faster rendering
---@param levelData table Level data from LDtk
function LDtkTilemapRenderSystem:cacheLayersForLevel(levelData)
    if not levelData or not levelData.layerInstances then
        print("[LDtkRenderSystem] ERROR: No layer instances in level data")
        return
    end
    
    -- Clear existing cache for this level
    self.levelLayersCache = {}
    print("[LDtkRenderSystem] Caching layers for level: " .. levelData.identifier)
    
    -- Process each layer from bottom to top
    for i = #levelData.layerInstances, 1, -1 do
        local layer = levelData.layerInstances[i]
        local layerId = layer.__identifier
        local layerType = layer.__type
        
        if self.debugMode then
            print("[LDtkRenderSystem] Processing layer: " .. layerId .. " (" .. layerType .. ")")
        end
        
        if layerType == "Tiles" then
            self:cacheTilesLayer(layer)
        end
    end
    
    print("[LDtkRenderSystem] Cached " .. #self.levelLayersCache .. " layers for level " .. levelData.identifier)
end

-- Cache a Tiles layer for rendering
---@param layer table Layer instance data
function LDtkTilemapRenderSystem:cacheTilesLayer(layer)
    if not layer or not layer.gridTiles or #layer.gridTiles == 0 then
        if self.debugMode then
            print("[LDtkRenderSystem] No tiles in layer: " .. layer.__identifier)
        end
        return
    end
    
    local tilesetDefUid = layer.__tilesetDefUid
    if not tilesetDefUid or not self.tileCache[tilesetDefUid] then
        print("[LDtkRenderSystem] ERROR: Tileset not found for layer: " .. layer.__identifier)
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
    
    if self.debugMode then
        print("[LDtkRenderSystem] Cached layer " .. layer.__identifier .. 
              " with " .. #layer.gridTiles .. " tiles using tileset " .. 
              self.tileCache[tilesetDefUid].identifier)
    end
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
    
    if self.debugMode and math.random() < 0.001 then -- Log occasionally
        print("[LDtkRenderSystem] Mapped color RGB(" .. r .. "," .. g .. "," .. b .. 
              ") to index " .. bestIndex)
    end
    
    return bestIndex
end

---@param renderer table
function LDtkTilemapRenderSystem:run(renderer)
    -- If this is the first run, check the TextureManager instance
    if self.frameCounter == 0 then
        print("[LDtkRenderSystem] TextureManager instance ID: " .. TextureManager.getInstanceId())
        print("[LDtkRenderSystem] --- Checking TextureManager Tileset Cache ---")
        TextureManager.dumpTilesetDebugInfo()
    end
    
    -- Increment frame counter for periodic stats logging
    self.frameCounter = self.frameCounter + 1
    
    -- Log stats every 300 frames (approximately every 5 seconds at 60 FPS)
    if self.debugMode and self.frameCounter % 300 == 0 then
        print(string.format("[LDtkRenderSystem] Rendering level: %s (frame %d)", 
            self.currentLevel, self.frameCounter))
    end
    
    local startTime = nil
    if self.debugMode and self.frameCounter % 300 == 0 then
        startTime = love.timer.getTime()
    end
    
    -- Render all cached layers
    local totalRenderedTiles = 0
    for i, layerCache in ipairs(self.levelLayersCache) do
        local tilesRendered = self:renderLayer(renderer, layerCache)
        totalRenderedTiles = totalRenderedTiles + tilesRendered
    end
    
    -- Log performance stats periodically
    if self.debugMode and startTime and self.frameCounter % 300 == 0 then
        local endTime = love.timer.getTime()
        local renderTime = (endTime - startTime) * 1000 -- Convert to milliseconds
        print(string.format("[LDtkRenderSystem] Rendered %d tiles in %.2f ms (%.2f tiles/ms)", 
            totalRenderedTiles, renderTime, totalRenderedTiles / renderTime))
    end
end

-- Render a specific layer
---@param renderer table
---@param layerCache table Cached layer data
---@return number Number of tiles rendered
function LDtkTilemapRenderSystem:renderLayer(renderer, layerCache)
    local tilesetCache = self.tileCache[layerCache.tilesetUid]
    if not tilesetCache then
        print("[LDtkRenderSystem] ERROR: Tileset not found for layer: " .. layerCache.identifier)
        return 0
    end
    
    -- Get the camera to check if tiles are visible
    local camera = renderer.camera
    if not camera then
        print("[LDtkRenderSystem] ERROR: No camera available for rendering")
        return 0
    end
    
    local visibleTiles = 0
    local totalTiles = #layerCache.tiles
    
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
            visibleTiles = visibleTiles + 1
        end
    end
    
    if self.debugMode and self.frameCounter % 300 == 0 then
        local visibilityPercent = math.floor((visibleTiles / totalTiles) * 100)
        print(string.format("[LDtkRenderSystem] Layer %s: Rendered %d/%d tiles (%d%%)", 
            layerCache.identifier, visibleTiles, totalTiles, visibilityPercent))
    end
    
    return visibleTiles
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
    -- Check if we have texture data from TextureManager
    if tilesetCache.textureData then
        -- Use the actual texture data to render the tile
        self:renderTileFromTextureData(renderer, tilesetCache, px, py, srcX, srcY, gridSize)
    else
        -- Fallback to simplified rendering with colored rectangles
        self:renderSimplifiedTile(renderer, tilesetCache, px, py, srcX, srcY, gridSize)
    end
end

-- Render a tile using actual texture data from the TextureManager
---@param renderer table
---@param tilesetCache table Tileset cache data
---@param px number Pixel x position in world
---@param py number Pixel y position in world
---@param srcX number Source x position in tileset
---@param srcY number Source y position in tileset
---@param gridSize number Size of the tile grid
function LDtkTilemapRenderSystem:renderTileFromTextureData(renderer, tilesetCache, px, py, srcX, srcY, gridSize)
    -- Convert world coordinates to screen coordinates
    local screenX, screenY = renderer:worldToScreen(px, py)

    -- Calculate the starting position in the texture data
    local startX = math.floor(srcX / 8) * gridSize + 1  -- +1 because Lua arrays are 1-indexed
    local startY = math.floor(srcY / 8) * gridSize + 1

    -- Track if we actually drew anything for this tile
    local pixelsDrawn = 0
    local totalPixels = 0

    -- Draw the tile pixel by pixel
    for dy = 0, gridSize - 1 do
        local srcY = startY + dy
        if tilesetCache.textureData[srcY] then  -- Check if row exists
            for dx = 0, gridSize - 1 do
                local srcX = startX + dx
                totalPixels = totalPixels + 1
                
                if tilesetCache.textureData[srcY][srcX] and tilesetCache.textureData[srcY][srcX] > 0 then
                    -- Get the color index from the texture data
                    local pixelColorIndex = tilesetCache.textureData[srcY][srcX]
                    
                    -- Draw the pixel at the screen position
                    love.graphics.setColor(renderer.COLORS[pixelColorIndex])
                    love.graphics.points(math.floor(screenX + dx), math.floor(screenY + dy))
                    pixelsDrawn = pixelsDrawn + 1
                end
            end
        end
    end
    
    -- If in super verbose debug mode, log tile rendering details occasionally
    if self.debugMode and math.random() < 0.0001 then  -- Only log about 0.01% of tiles to avoid spamming
        print(string.format("[LDtkRenderSystem] Tile at (%d,%d): Drew %d/%d pixels using texture data", 
            px, py, pixelsDrawn, totalPixels))
    end
    
    -- Optionally, draw a tile boundary for debugging
    if self.showTileBoundaries then
        renderer:draw_rectangle(
            px,
            py,
            gridSize,
            gridSize,
            1,  -- darkest color
            false  -- not filled (outline)
        )
    end
end

-- Simplified tile rendering without texture data (fallback)
---@param renderer table
---@param tilesetCache table Tileset cache data
---@param px number Pixel x position in world
---@param py number Pixel y position in world
---@param srcX number Source x position in tileset
---@param srcY number Source y position in tileset
---@param gridSize number Size of the tile grid
function LDtkTilemapRenderSystem:renderSimplifiedTile(renderer, tilesetCache, px, py, srcX, srcY, gridSize)
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
    
    -- Log simplified rendering occasionally
    if self.debugMode and math.random() < 0.0001 then
        print(string.format("[LDtkRenderSystem] Using simplified rendering for tile at (%d,%d) with color index %d", 
            px, py, colorIndex))
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
    if self.showTileBoundaries then
        renderer:draw_rectangle(
            px,
            py,
            gridSize,
            gridSize,
            1,  -- darkest color
            false  -- not filled (outline)
        )
    end
end

-- Set the current level to render
---@param levelIdentifier string Level identifier
function LDtkTilemapRenderSystem:setLevel(levelIdentifier)
    if self.currentLevel == levelIdentifier then
        print("[LDtkRenderSystem] Already on level: " .. levelIdentifier)
        return
    end
    
    print("[LDtkRenderSystem] Changing level from " .. self.currentLevel .. " to " .. levelIdentifier)
    self.currentLevel = levelIdentifier
    
    -- Reset frame counter
    self.frameCounter = 0
    
    -- Reinitialize tile cache for the new level
    self:initTileCache()
end

-- Toggle tile boundaries for debugging
---@param enabled boolean|nil If provided, explicitly sets the state; otherwise toggles
function LDtkTilemapRenderSystem:toggleTileBoundaries(enabled)
    if enabled ~= nil then
        self.showTileBoundaries = enabled
    else
        self.showTileBoundaries = not self.showTileBoundaries
    end
    
    print("[LDtkRenderSystem] Tile boundaries " .. (self.showTileBoundaries and "enabled" or "disabled"))
end

-- Toggle debug mode
---@param enabled boolean|nil If provided, explicitly sets the state; otherwise toggles
function LDtkTilemapRenderSystem:toggleDebugMode(enabled)
    if enabled ~= nil then
        self.debugMode = enabled
    else
        self.debugMode = not self.debugMode
    end
    
    print("[LDtkRenderSystem] Debug mode " .. (self.debugMode and "enabled" or "disabled"))
end

-- Print rendering statistics
function LDtkTilemapRenderSystem:printStats()
    print("[LDtkRenderSystem] === Rendering Statistics ===")
    print("[LDtkRenderSystem] Current level: " .. self.currentLevel)
    print("[LDtkRenderSystem] Cached layers: " .. #self.levelLayersCache)
    
    local totalTiles = 0
    for _, layerCache in ipairs(self.levelLayersCache) do
        totalTiles = totalTiles + #layerCache.tiles
    end
    
    print("[LDtkRenderSystem] Total tiles: " .. totalTiles)
    print("[LDtkRenderSystem] Tile boundaries: " .. (self.showTileBoundaries and "visible" or "hidden"))
    print("[LDtkRenderSystem] Debug mode: " .. (self.debugMode and "enabled" or "disabled"))
    
    -- Print layer details
    print("[LDtkRenderSystem] Layer details:")
    for i, layerCache in ipairs(self.levelLayersCache) do
        print(string.format("[LDtkRenderSystem]   %d. %s: %d tiles (Tileset: %s)", 
            i, layerCache.identifier, #layerCache.tiles, 
            self.tileCache[layerCache.tilesetUid] and self.tileCache[layerCache.tilesetUid].identifier or "unknown"))
    end
    
    print("[LDtkRenderSystem] ============================")
end

return LDtkTilemapRenderSystem
