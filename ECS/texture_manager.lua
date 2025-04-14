-- ECS/texture_manager.lua
-- Global texture manager for loading and caching game textures

---@class TextureManager
---@field textureCache table<string, table> Cache of loaded textures by path
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

        print("TextureManager instance created")
    end

    return instance
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
        print("TextureManager initialized with " .. #TextureManager.getColorMapKeys() .. " color mappings")
        print("Color mappings:")
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
    print("=== Texture Cache Statistics ===")
    print("Total textures: " .. stats.totalTextures)
    print("Total pixels: " .. stats.totalPixels)
    if stats.largestTexture.path ~= "" then
        print("Largest texture: " .. stats.largestTexture.path ..
              " (" .. stats.largestTexture.width .. "x" .. stats.largestTexture.height ..
              " = " .. stats.largestTexture.pixels .. " pixels)")
    end
    print("===============================")
end

-- Clear the texture cache
function TextureManager.clearCache()
    local manager = TextureManager.getInstance()
    manager.textureCache = {}
    print("Texture cache cleared")
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
        print("Attempting to load texture: " .. path)
    end

    -- Check if the sprite is already in the cache
    if manager.textureCache[path] then
        if manager.debugMode then
            print("Texture already in cache: " .. path ..
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
        print("ERROR: Failed to load texture: " .. path)
        print("Error details: " .. tostring(imageData)) -- imageData contains error message
        return {}, 0, 0
    end

    -- Get the image dimensions
    local sheetWidth = imageData:getWidth()
    local sheetHeight = imageData:getHeight()

    if manager.debugMode then
        print("Successfully loaded image: " .. path .. " (" .. sheetWidth .. "x" .. sheetHeight .. ")")
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
                        print("WARNING: Unmapped color at (" .. x .. "," .. y .. "): " .. colorKey)
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
        print("=== Texture Conversion Complete: " .. path .. " ===")
        print("Dimensions: " .. sheetWidth .. "x" .. sheetHeight .. " (" .. (sheetWidth * sheetHeight) .. " pixels)")
        print("Mapped pixels: " .. colorMappingStats.mapped)
        print("Unmapped pixels: " .. colorMappingStats.unmapped)
        print("Transparent pixels: " .. colorMappingStats.transparent)

        -- Print most common colors
        print("Top colors used:")
        local colorList = {}
        for color, count in pairs(colorMappingStats.colorCounts) do
            table.insert(colorList, {color = color, count = count})
        end

        table.sort(colorList, function(a, b) return a.count > b.count end)
        for i = 1, math.min(5, #colorList) do
            local color = colorList[i]
            local mappedTo = manager.colorMap[color.color] or "unmapped"
            print("  " .. color.color .. " -> " .. mappedTo .. " (" .. color.count .. " pixels)")
        end

        -- Update and print cache statistics
        TextureManager.printCacheStats()
        print("===========================================")
    else
        print("Loaded texture: " .. path .. " (" .. sheetWidth .. "x" .. sheetHeight .. ")")
    end

    return spriteData, sheetWidth, sheetHeight
end

return TextureManager
