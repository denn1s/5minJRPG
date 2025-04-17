-- ECS/ldtk/ldtk_tilemap_setup_system.lua
-- System for loading all LDtk tilemaps at game startup

local Systems = require("ECS.systems")
local TextureManager = require("ECS.texture_manager")

---@class LDtkTilemapSetupSystem : SetupSystem
---@field ecs table ECS instance
---@field ldtkParser table LDtk parser
---@field debugMode boolean Whether to print debug information
local LDtkTilemapSetupSystem = setmetatable({}, {__index = Systems.SetupSystem})
LDtkTilemapSetupSystem.__index = LDtkTilemapSetupSystem

---@return LDtkTilemapSetupSystem
function LDtkTilemapSetupSystem.new()
    local system = Systems.SetupSystem.new()
    setmetatable(system, LDtkTilemapSetupSystem)
    system.debugMode = true
    return system
end

---@param ecs table
---@param ldtkParser table
---@return LDtkTilemapSetupSystem
function LDtkTilemapSetupSystem:init(ecs, ldtkParser)
    Systems.SetupSystem.init(self, ecs)
    self.ldtkParser = ldtkParser
    return self
end

function LDtkTilemapSetupSystem:run()
    print("[LDtkTilemapSetupSystem] *** STARTING TILESET LOADING ***")
    print("[LDtkTilemapSetupSystem] TextureManager instance ID: " .. TextureManager.getInstanceId())
    
    if not self.ldtkParser or not self.ldtkParser.data then
        print("[LDtkTilemapSetupSystem] ERROR: No LDtk data available")
        return
    end
    
    -- Load all tilesets defined in the LDtk file
    self:loadAllTilesets()
    
    -- Log success message
    print("[LDtkTilemapSetupSystem] All tilemaps loaded successfully")
    
    -- Print tileset cache stats
    TextureManager.printTilesetCacheStats()
    
    -- Dump the tileset cache debug info for inspection
    TextureManager.dumpTilesetDebugInfo()
    
    print("[LDtkTilemapSetupSystem] *** FINISHED TILESET LOADING ***")
end

-- Load all tilesets defined in the LDtk file
function LDtkTilemapSetupSystem:loadAllTilesets()
    local tilesets = self.ldtkParser:getTilesets()

    if #tilesets == 0 then
        print("LDtkTilemapSetupSystem: No tilesets found in LDtk file")
        return
    end

    print("LDtkTilemapSetupSystem: Loading " .. #tilesets .. " tilesets...")

    -- Process each tileset
    for _, tileset in ipairs(tilesets) do
        self:loadTileset(tileset)
    end

    print("LDtkTilemapSetupSystem: All tilesets loaded")
end

-- Load a single tileset using TextureManager
---@param tileset table Tileset definition from LDtk
function LDtkTilemapSetupSystem:loadTileset(tileset)
    local uid = tileset.uid
    local identifier = tileset.identifier
    local relPath = tileset.relPath
    local gridSize = tileset.tileGridSize
    local width = tileset.__cWid
    local height = tileset.__cHei

    -- Resolve the relative path using the parser's utility method
    local fullPath = self.ldtkParser:resolvePath(relPath)

    -- Debug output
    if self.debugMode then
        print(string.format("LDtkTilemapSetupSystem: Loading tileset %s (uid: %d)",
            identifier, uid))
        print(string.format("  Relative path: %s", relPath))
        print(string.format("  Full path: %s", fullPath))
        print(string.format("  Grid size: %d, Dimensions: %dx%d tiles",
            gridSize, width, height))
    end

    -- Use TextureManager to load and cache the tileset
    TextureManager.loadTileset(uid, identifier, fullPath, gridSize, width, height)
end

return LDtkTilemapSetupSystem
