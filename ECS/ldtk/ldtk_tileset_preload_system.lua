-- ECS/ldtk/ldtk_tileset_preload_system.lua
-- System for preloading tilesets needed by LDtk maps

local Systems = require("ECS.systems")
local TextureManager = require("ECS.texture_manager")

---@class LDtkTilesetPreloadSystem : SetupSystem
---@field ecs table ECS instance
---@field tilesets table<number, table> Tilesets to preload
---@field debugMode boolean Whether to print detailed debug information
local LDtkTilesetPreloadSystem = setmetatable({}, {__index = Systems.SetupSystem})
LDtkTilesetPreloadSystem.__index = LDtkTilesetPreloadSystem

---@return LDtkTilesetPreloadSystem
function LDtkTilesetPreloadSystem.new()
    local system = Systems.SetupSystem.new()
    setmetatable(system, LDtkTilesetPreloadSystem)
    system.tilesets = {}
    system.debugMode = true
    return system
end

---@param ecs table
---@return LDtkTilesetPreloadSystem
function LDtkTilesetPreloadSystem:init(ecs)
    Systems.SetupSystem.init(self, ecs)
    return self
end

function LDtkTilesetPreloadSystem:run()
    print("[LDtkTilesetPreloadSystem] Preloading standard tilesets...")
    
    -- Preload standard tilesets with hardcoded paths
    -- This ensures they're available regardless of path resolution issues
    self:preloadStandardTilesets()
    
    -- Print the state of the TextureManager cache
    if self.debugMode then
        TextureManager.dumpTilesetDebugInfo()
    end
    
    print("[LDtkTilesetPreloadSystem] Preloading complete")
end

-- Preload the standard set of tilesets used in the game
function LDtkTilesetPreloadSystem:preloadStandardTilesets()
    -- Town tileset
    print("[LDtkTilesetPreloadSystem] Loading Town tileset...")
    TextureManager.loadTileset(
        2,                         -- UID
        "Town",                    -- Identifier
        "assets/spritesheets/town.png",  -- Full path
        8,                         -- Grid size
        16,                        -- Width in tiles
        16                         -- Height in tiles
    )
    
    -- Interior tileset
    print("[LDtkTilesetPreloadSystem] Loading Interior tileset...")
    TextureManager.loadTileset(
        10,
        "Interior",
        "assets/spritesheets/interior.png",
        8,
        16,
        16
    )
    
    -- Dungeon tileset
    print("[LDtkTilesetPreloadSystem] Loading Dungeon tileset...")
    TextureManager.loadTileset(
        14,
        "Dungeon",
        "assets/spritesheets/dungeon.png",
        8,
        16,
        16
    )
    
    -- Hero tileset
    print("[LDtkTilesetPreloadSystem] Loading Hero tileset...")
    TextureManager.loadTileset(
        16,
        "Hero",
        "assets/spritesheets/hero.png",
        16,
        3,
        4
    )
end

-- Register a custom tileset to be preloaded (for extensibility)
---@param uid number Tileset UID
---@param identifier string Tileset identifier
---@param path string Path to the tileset image
---@param gridSize number Tile grid size
---@param width number Width in tiles
---@param height number Height in tiles
---@return LDtkTilesetPreloadSystem
function LDtkTilesetPreloadSystem:registerTileset(uid, identifier, path, gridSize, width, height)
    self.tilesets[uid] = {
        uid = uid,
        identifier = identifier,
        path = path,
        gridSize = gridSize,
        width = width,
        height = height
    }
    return self
end

return LDtkTilesetPreloadSystem
