-- ECS/ldtk/init.lua
-- Index file that imports and exports all modules from the LDtk directory

local LDtk = {}

-- Import all modules from this directory
LDtk.Parser = require("ECS.ldtk.ldtk_parser")
LDtk.LoadSystem = require("ECS.ldtk.ldtk_system")
LDtk.TilemapSystem = require("ECS.ldtk.ldtk_tilemap_system")
LDtk.TilemapRenderSystem = require("ECS.ldtk.ldtk_tilemap_render_system")
LDtk.DoorSystem = require("ECS.ldtk.ldtk_door_system")

-- Export the modules
return LDtk
