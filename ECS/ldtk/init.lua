-- ECS/ldtk/init.lua
-- Index file that imports and exports all modules from the LDtk directory

local LDtk = {}

-- Import all modules from this directory
LDtk.LDtkManager = require("ECS.ldtk.ldtk_manager")
LDtk.TilemapRenderSystem = require("ECS.ldtk.ldtk_tilemap_render_system")
LDtk.TilesetPreloadSystem = require("ECS.ldtk.ldtk_tileset_preload_system")

-- Export the modules
return LDtk
