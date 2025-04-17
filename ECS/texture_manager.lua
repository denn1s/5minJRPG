-- ECS/texture_manager.lua
-- Global texture manager for loading and caching game textures and tilesets

---@class TextureManager
---@field textureCache table<string, table> Cache of loaded textures by path
---@field tilesetCache table<number, table> Cache of loaded tilesets by UID
---@field tilesetPathMap table<string, number> Map from path to UID for reverse lookup
---@field tilesetIdentifierMap table<string, number> Map from identifier to UID
---@field colorMap table<string, number> Mapping of RGB values to color indices
---@field debugMode boolean Whether to print detailed debug information
local TextureManager = {}

-- Singleton instance
local instance = nil

-- Get the singleton instance of the texture manager
---@return TextureManager
function TextureManager.getInstance()
    if not instance then
        -- Create a new instance if one doesn't exist
        instance = {
            textureCache = {},
            tilesetCache = {},      -- Cache for LDtk tilesets by UID
            tilesetPathMap = {},    -- Map from path to UID for reverse lookup
            tilesetIdentifierMap = {}, -- Map from identifier to UID
            instanceId = tostring(math.random(10000, 99999)), -- Unique ID for this instance

            -- Default color mapping for sprites
            -- Format: "r,g,b" -> colorIndex
            colorMap = {
                ["0,0,0"] = 1,         -- Black -> Darkest (index 1)
                ["51,44,80"] = 2,      -- Dark blue-purple -> Dark (index 2)
                ["70,135,143"] = 3,    -- Teal -> Light (index 3)
                ["226,243,228"] = 4    -- Off-white -> Lightest (index 4)
            },

            -- Enable debug mode by default
            debugMode = true
        }

        print("[TextureManager] Instance created with ID: " .. instance.instanceId)
    end

    return instance
end

function TextureManager.getInstanceId()
    local manager = TextureManager.getInstance()
    return manager.instanceId
end

-- Initialize the texture manager with custom settings
---@param colorMap? table<string, number> Optional custom color mapping
---@param debugMode? boolean Whether to print detailed debug information
---@return TextureManager
function TextureManager.init(colorMap, debugMode)
    local manager = TextureManager.getInstance()

    -- Override default colorMap if provided
    if colorMap then
        manager.colorMap = colorMap
    end

    -- Set debug mode if specified
    if debugMode ~= nil then
        manager.debugMode = debugMode
    end

    if manager.debugMode then
        print("[TextureManager] Initialized with " .. #TextureManager.getColorMapKeys() .. " color mappings")
        print("[TextureManager] Color mappings:")
        for key, value in pairs(manager.colorMap) do
            print("  " .. key .. " -> " .. value)
        end
    end

    return manager
end

-- Helper function to get color map keys
---@return string[]
function TextureManager.getColorMapKeys()
    local manager = TextureManager.getInstance()
    local keys = {}
    for k, _ in pairs(manager.colorMap) do
        table.insert(keys, k)
    end
    return keys
end

-- Generate a cache key string from an RGB color
---@param r number Red component (0-255)
---@param g number Green component (0-255)
---@param b number Blue component (0-255)
---@return string
function TextureManager.getColorKey(r, g, b)
    return string.format("%d,%d,%d", r, g, b)
end

-- Get cache statistics
---@return table
function TextureManager.getCacheStats()
    local manager = TextureManager.getInstance()
    local stats = {
        totalTextures = 0,
        totalPixels = 0,
        largestTexture = {path = "", width = 0, height = 0, pixels = 0}
    }

    for path, texture in pairs(manager.textureCache) do
        stats.totalTextures = stats.totalTextures + 1
        local pixels = texture.width * texture.height
        stats.totalPixels = stats.totalPixels + pixels

        if pixels > stats.largestTexture.pixels then
            stats.largestTexture.path = path
            stats.largestTexture.width = texture.width
            stats.largestTexture.height = texture.height
            stats.largestTexture.pixels = pixels
        end
    end

    return stats
end

-- Print texture cache statistics
function TextureManager.printCacheStats()
    local stats = TextureManager.getCacheStats()
    print("[TextureManager] === Texture Cache Statistics ===")
    print("[TextureManager] Total textures: " .. stats.totalTextures)
    print("[TextureManager] Total pixels: " .. stats.totalPixels)
    if stats.largestTexture.path ~= "" then
        print("[TextureManager] Largest texture: " .. stats.largestTexture.path ..
              " (" .. stats.largestTexture.width .. "x" .. stats.largestTexture.height ..
              " = " .. stats.largestTexture.pixels .. " pixels)")
    end
    print("[TextureManager] ===============================")
end

-- Print tileset cache statistics
function TextureManager.printTilesetCacheStats()
    local manager = TextureManager.getInstance()
    local stats = {
        totalTilesets = 0,
        totalTiles = 0,
        totalMemoryUsage = 0
    }

    local tilesetList = {}

    for uid, tileset in pairs(manager.tilesetCache) do
        stats.totalTilesets = stats.totalTilesets + 1

        local tilesInTileset = 0
        if tileset.width and tileset.height then
            tilesInTileset = tileset.width * tileset.height
            stats.totalTiles = stats.totalTiles + tilesInTileset
        end

        -- Calculate approximate memory usage (rough estimate)
        local memoryUsage = 0
        if tileset.textureWidth and tileset.textureHeight then
            memoryUsage = tileset.textureWidth * tileset.textureHeight * 4 -- 4 bytes per pixel (RGBA)
            stats.totalMemoryUsage = stats.totalMemoryUsage + memoryUsage
        end

        table.insert(tilesetList, {
            uid = uid,
            identifier = tileset.identifier,
            tiles = tilesInTileset,
            memory = memoryUsage
        })
    end

    -- Sort tilesets by memory usage
    table.sort(tilesetList, function(a, b) return a.memory > b.memory end)

    print("[TextureManager] === Tileset Cache Statistics ===")
    print("[TextureManager] Total tilesets: " .. stats.totalTilesets)
    print("[TextureManager] Total tiles: " .. stats.totalTiles)
    print("[TextureManager] Estimated memory usage: " .. math.floor(stats.totalMemoryUsage / 1024) .. " KB")

    if #tilesetList > 0 then
        print("[TextureManager] Tilesets (sorted by memory usage):")
        for i, ts in ipairs(tilesetList) do
            if i <= 5 then -- Show top 5 by default
                print(string.format("[TextureManager]   %s (UID: %d): %d tiles, %.2f KB",
                    ts.identifier, ts.uid, ts.tiles, ts.memory / 1024))
            end
        end

        if #tilesetList > 5 then
            print("[TextureManager]   ... and " .. (#tilesetList - 5) .. " more")
        end
    end

    print("[TextureManager] ================================")
end

-- Clear the texture cache
function TextureManager.clearCache()
    local manager = TextureManager.getInstance()
    manager.textureCache = {}
    print("[TextureManager] Texture cache cleared")
end

-- Clear the tileset cache
function TextureManager.clearTilesetCache()
    local manager = TextureManager.getInstance()
    manager.tilesetCache = {}
    manager.tilesetPathMap = {}
    manager.tilesetIdentifierMap = {}
    print("[TextureManager] Tileset cache cleared")
end

-- Check if a texture is already loaded in the cache
---@param path string Path to the texture file
---@return boolean
function TextureManager.isTextureLoaded(path)
    local manager = TextureManager.getInstance()
    return manager.textureCache[path] ~= nil
end

-- Get a loaded texture from the cache
---@param path string Path to the texture file
---@return table|nil texture Texture data or nil if not found
---@return number width Texture width (0 if not found)
---@return number height Texture height (0 if not found)
function TextureManager.getTexture(path)
    local manager = TextureManager.getInstance()
    if manager.textureCache[path] then
        return manager.textureCache[path].data,
               manager.textureCache[path].width,
               manager.textureCache[path].height
    end
    return nil, 0, 0
end

-- Load a texture and convert to the indexed color format
---@param path string Path to the texture file
---@return table spriteData
---@return number sheetWidth
---@return number sheetHeight
function TextureManager.loadTexture(path)
    local manager = TextureManager.getInstance()

    if manager.debugMode then
        print("[TextureManager] Attempting to load texture: " .. path)
    end

    -- Check if the sprite is already in the cache
    if manager.textureCache[path] then
        if manager.debugMode then
            print("[TextureManager] Texture already in cache: " .. path ..
                  " (" .. manager.textureCache[path].width .. "x" .. manager.textureCache[path].height .. ")")
        end
        return manager.textureCache[path].data,
               manager.textureCache[path].width,
               manager.textureCache[path].height
    end

    -- Load the image using Love2D
    local success, imageData
    success, imageData = pcall(function()
        return love.image.newImageData(path)
    end)

    if not success then
        print("[TextureManager] ERROR: Failed to load texture: " .. path)
        print("[TextureManager] Error details: " .. tostring(imageData)) -- imageData contains error message
        return {}, 0, 0
    end

    -- Get the image dimensions
    local sheetWidth = imageData:getWidth()
    local sheetHeight = imageData:getHeight()

    if manager.debugMode then
        print("[TextureManager] Successfully loaded image: " .. path .. " (" .. sheetWidth .. "x" .. sheetHeight .. ")")
    end

    -- Convert the image to our color-indexed format
    local spriteData = {}
    local colorMappingStats = {
        mapped = 0,
        unmapped = 0,
        transparent = 0,
        colorCounts = {}
    }

    -- For each pixel in the image
    for y = 0, sheetHeight - 1 do
        spriteData[y + 1] = {}
        for x = 0, sheetWidth - 1 do
            -- Get the pixel color from the image
            local r, g, b, a = imageData:getPixel(x, y)

            -- Skip transparent pixels
            if a > 0 then
                -- Convert to our color map
                local colorKey = TextureManager.getColorKey(math.floor(r * 255), math.floor(g * 255), math.floor(b * 255))
                local colorIndex = manager.colorMap[colorKey]

                -- Count for statistics
                colorMappingStats.colorCounts[colorKey] = (colorMappingStats.colorCounts[colorKey] or 0) + 1

                -- If the color isn't in our map, it's transparent
                if colorIndex then
                    spriteData[y + 1][x + 1] = colorIndex
                    colorMappingStats.mapped = colorMappingStats.mapped + 1
                else
                    spriteData[y + 1][x + 1] = 0
                    colorMappingStats.unmapped = colorMappingStats.unmapped + 1

                    if manager.debugMode and colorMappingStats.unmapped <= 10 then
                        -- Only show first 10 unmapped colors to avoid spam
                        print("[TextureManager] WARNING: Unmapped color at (" .. x .. "," .. y .. "): " .. colorKey)
                    end
                end
            else
                -- Transparent
                spriteData[y + 1][x + 1] = 0
                colorMappingStats.transparent = colorMappingStats.transparent + 1
            end
        end
    end

    -- Store in cache
    manager.textureCache[path] = {
        data = spriteData,
        width = sheetWidth,
        height = sheetHeight,
        loadTime = os.time() -- Optional: track when it was loaded
    }

    if manager.debugMode then
        print("[TextureManager] === Texture Conversion Complete: " .. path .. " ===")
        print("[TextureManager] Dimensions: " .. sheetWidth .. "x" .. sheetHeight .. " (" .. (sheetWidth * sheetHeight) .. " pixels)")
        print("[TextureManager] Mapped pixels: " .. colorMappingStats.mapped)
        print("[TextureManager] Unmapped pixels: " .. colorMappingStats.unmapped)
        print("[TextureManager] Transparent pixels: " .. colorMappingStats.transparent)

        -- Print most common colors
        print("[TextureManager] Top colors used:")
        local colorList = {}
        for color, count in pairs(colorMappingStats.colorCounts) do
            table.insert(colorList, {color = color, count = count})
        end

        table.sort(colorList, function(a, b) return a.count > b.count end)
        for i = 1, math.min(5, #colorList) do
            local color = colorList[i]
            local mappedTo = manager.colorMap[color.color] or "unmapped"
            print("[TextureManager]   " .. color.color .. " -> " .. mappedTo .. " (" .. color.count .. " pixels)")
        end

        -- Update and print cache statistics
        TextureManager.printCacheStats()
        print("[TextureManager] ===========================================")
    else
        print("[TextureManager] Loaded texture: " .. path .. " (" .. sheetWidth .. "x" .. sheetHeight .. ")")
    end

    return spriteData, sheetWidth, sheetHeight
end

-- Load an LDtk tileset and cache it
---@param uid number Tileset UID
---@param identifier string Tileset identifier
---@param path string Path to the tileset image
---@param gridSize number Tile grid size
---@param width number Width in tiles
---@param height number Height in tiles
---@return table Cached tileset data
function TextureManager.loadTileset(uid, identifier, path, gridSize, width, height)
    local manager = TextureManager.getInstance()
    
    -- Ensure uid is always a number
    uid = tonumber(uid)
    if not uid then
        print(string.format("[TextureManager] ERROR: Invalid UID for tileset %s: %s (must be a number)", 
            identifier, tostring(uid)))
        return nil
    end
    
    -- Verbose debugging for tileset loading
    print(string.format("[TextureManager] LOADING TILESET: uid=%d (type: %s), identifier='%s', path='%s'", 
        uid, type(uid), identifier, path))
    
    -- Check if already cached by UID
    if manager.tilesetCache[uid] then
        if manager.debugMode then
            print("[TextureManager] Tileset already cached by UID: " .. identifier .. " (UID: " .. uid .. ")")
        end
        return manager.tilesetCache[uid]
    end
    
    -- Also check if we have this tileset by path or identifier
    local existingUidByPath = manager.tilesetPathMap[path]
    local existingUidByIdentifier = manager.tilesetIdentifierMap[identifier]
    
    if existingUidByPath then
        print(string.format("[TextureManager] Tileset already cached by PATH: %s (UID was %d, found as %d)", 
            path, uid, existingUidByPath))
        return manager.tilesetCache[existingUidByPath]
    end
    
    if existingUidByIdentifier then
        print(string.format("[TextureManager] Tileset already cached by IDENTIFIER: %s (UID was %d, found as %d)", 
            identifier, uid, existingUidByIdentifier))
        return manager.tilesetCache[existingUidByIdentifier]
    end
    
    -- If we get here, we need to load the tileset
    print(string.format("[TextureManager] Loading new tileset: %s (uid=%d, path=%s)", 
        identifier, uid, path))
    
    -- Load the texture using our existing method
    local textureData, textureWidth, textureHeight = TextureManager.loadTexture(path)
    
    -- Create tileset data
    local tileset = {
        uid = uid,
        identifier = identifier,
        path = path,
        gridSize = gridSize,
        width = width,
        height = height,
        textureData = textureData,
        textureWidth = textureWidth,
        textureHeight = textureHeight,
        loadTime = os.time()
    }
    
    -- Store in caches with multiple lookup options
    manager.tilesetCache[uid] = tileset
    manager.tilesetPathMap[path] = uid
    manager.tilesetIdentifierMap[identifier] = uid
    
    print(string.format("[TextureManager] Successfully cached tileset %s (UID: %d) with %dx%d tiles", 
        identifier, uid, width, height))
    
    return tileset
end

-- Get a tileset from the cache by UID
---@param uid number|string Tileset UID or path or identifier
---@return table|nil Tileset data or nil if not found
function TextureManager.getTileset(uid)
    local manager = TextureManager.getInstance()

    -- If uid is actually a string, it might be a path or identifier
    if type(uid) == "string" then
        -- Try to look up by path
        local uidByPath = manager.tilesetPathMap[uid]
        if uidByPath then
            return manager.tilesetCache[uidByPath]
        end

        -- Try to look up by identifier
        local uidByIdentifier = manager.tilesetIdentifierMap[uid]
        if uidByIdentifier then
            return manager.tilesetCache[uidByIdentifier]
        end

        -- Print warning with debug info if not found
        if manager.debugMode then
            print(string.format("[TextureManager] WARNING: Tileset not found with path/identifier '%s'", uid))
            print("[TextureManager] Available paths:")
            for path, _ in pairs(manager.tilesetPathMap) do
                print("  - " .. path)
            end
            print("[TextureManager] Available identifiers:")
            for id, _ in pairs(manager.tilesetIdentifierMap) do
                print("  - " .. id)
            end
        end

        return nil
    end

    -- Otherwise, look up by UID
    local tileset = manager.tilesetCache[uid]

    if not tileset and manager.debugMode then
        print(string.format("[TextureManager] WARNING: Tileset with UID %d not found in cache", uid))
        print("[TextureManager] Available UIDs:")
        for cachedUid, _ in pairs(manager.tilesetCache) do
            print("  - " .. cachedUid)
        end
    end

    return tileset
end

-- Get a tileset by identifier
---@param identifier string Tileset identifier
---@return table|nil Tileset data or nil if not found
function TextureManager.getTilesetByIdentifier(identifier)
    local manager = TextureManager.getInstance()

    local uid = manager.tilesetIdentifierMap[identifier]
    if uid then
        return manager.tilesetCache[uid]
    end

    if manager.debugMode then
        print("[TextureManager] WARNING: Tileset with identifier '" .. identifier .. "' not found in cache")
        print("[TextureManager] Available identifiers:")
        for id, _ in pairs(manager.tilesetIdentifierMap) do
            print("  - " .. id)
        end
    end

    return nil
end

-- Get a tile from a tileset by grid coordinates
---@param tilesetUid number Tileset UID
---@param tileX number X grid coordinate
---@param tileY number Y grid coordinate
---@return table|nil Tile data or nil if not found
function TextureManager.getTile(tilesetUid, tileX, tileY)
    local manager = TextureManager.getInstance()
    local tileset = manager.tilesetCache[tilesetUid]

    if not tileset or not tileset.textureData then
        if manager.debugMode then
            print("[TextureManager] ERROR: Cannot get tile - tileset " .. tilesetUid .. " not found or has no texture data")
        end
        return nil
    end

    -- Calculate pixel coordinates
    local pixelX = tileX * tileset.gridSize
    local pixelY = tileY * tileset.gridSize

    -- Extract the tile data
    local tileData = TextureManager.extractTileData(tileset, tileX, tileY)

    -- Return tile information
    return {
        tilesetUid = tilesetUid,
        gridX = tileX,
        gridY = tileY,
        pixelX = pixelX,
        pixelY = pixelY,
        gridSize = tileset.gridSize,
        data = tileData
    }
end

-- Extract pixel data for a specific tile from a tileset
---@param tileset table Tileset data
---@param tileX number X grid coordinate
---@param tileY number Y grid coordinate
---@return table Pixel data for the tile
function TextureManager.extractTileData(tileset, tileX, tileY)
    local pixelData = {}
    local startX = tileX * tileset.gridSize + 1  -- +1 because Lua arrays are 1-indexed
    local startY = tileY * tileset.gridSize + 1
    local endX = startX + tileset.gridSize - 1
    local endY = startY + tileset.gridSize - 1

    -- Make sure we don't go out of bounds
    endX = math.min(endX, tileset.textureWidth)
    endY = math.min(endY, tileset.textureHeight)

    -- Extract the tile data
    for y = startY, endY do
        local row = {}
        if tileset.textureData[y] then  -- Check if row exists
            for x = startX, endX do
                if tileset.textureData[y][x] then  -- Check if column exists
                    table.insert(row, tileset.textureData[y][x])
                else
                    table.insert(row, 0)  -- Default to transparent
                end
            end
        else
            -- Fill with transparent pixels if row doesn't exist
            for _ = startX, endX do
                table.insert(row, 0)
            end
        end
        table.insert(pixelData, row)
    end

    return pixelData
end

-- Dump memory usage statistics
function TextureManager.dumpMemoryStats()
    local manager = TextureManager.getInstance()

    print("[TextureManager] === Memory Usage Statistics ===")
    print("[TextureManager] Texture cache entries: " .. TextureManager.countTableEntries(manager.textureCache))
    print("[TextureManager] Tileset cache entries: " .. TextureManager.countTableEntries(manager.tilesetCache))

    local textureMemory = collectgarbage("count") -- Gets current Lua memory usage in KB
    print(string.format("[TextureManager] Current Lua memory usage: %.2f KB", textureMemory))
    print("[TextureManager] ================================")
end

-- Helper function to count table entries
---@param t table Table to count
---@return number Number of entries
function TextureManager.countTableEntries(t)
    local count = 0
    for _, _ in pairs(t) do
        count = count + 1
    end
    return count
end

-- Dump detailed information about all cached tilesets
function TextureManager.dumpTilesetDebugInfo()
    local manager = TextureManager.getInstance()

    print("\n[TextureManager] === DETAILED TILESET DEBUG INFO ===")
    print(string.format("[TextureManager] Tilesets in cache: %d", TextureManager.countTableEntries(manager.tilesetCache)))
    print(string.format("[TextureManager] Path mappings: %d", TextureManager.countTableEntries(manager.tilesetPathMap)))
    print(string.format("[TextureManager] Identifier mappings: %d", TextureManager.countTableEntries(manager.tilesetIdentifierMap)))

    -- List all tilesets by UID
    print("\n[TextureManager] === TILESETS BY UID ===")
    for uid, tileset in pairs(manager.tilesetCache) do
        print(string.format("[TextureManager] UID %d: '%s' from '%s' (%dx%d tiles, grid size %d)",
            uid, tileset.identifier, tileset.path,
            tileset.width, tileset.height, tileset.gridSize))

        -- Check if texture data exists
        if tileset.textureData then
            local pixelCount = 0
            for y, row in pairs(tileset.textureData) do
                for x, pixel in pairs(row) do
                    if pixel > 0 then
                        pixelCount = pixelCount + 1
                    end
                end
            end
            print(string.format("[TextureManager]    - Texture data: YES (%d visible pixels)", pixelCount))
        else
            print("[TextureManager]    - Texture data: NO")
        end
    end

    -- List path mappings
    print("\n[TextureManager] === PATH TO UID MAPPINGS ===")
    for path, uid in pairs(manager.tilesetPathMap) do
        print(string.format("[TextureManager] Path '%s' -> UID %d", path, uid))
    end

    -- List identifier mappings
    print("\n[TextureManager] === IDENTIFIER TO UID MAPPINGS ===")
    for id, uid in pairs(manager.tilesetIdentifierMap) do
        print(string.format("[TextureManager] Identifier '%s' -> UID %d", id, uid))
    end

    print("[TextureManager] =======================================\n")
end

return TextureManager
