-- ECS/ldtk/ldtk_tileset_preload_system.lua
-- System for preloading tilesets needed by LDtk maps

local Systems = require("ECS.systems")
local TextureManager = require("ECS.texture_manager")
local LDtkManager = require("ECS.ldtk.ldtk_manager")

---@class LDtkTilesetPreloadSystem : SetupSystem
local LDtkTilesetPreloadSystem = setmetatable({}, {__index = Systems.SetupSystem})
LDtkTilesetPreloadSystem.__index = LDtkTilesetPreloadSystem

---@return LDtkTilesetPreloadSystem
function LDtkTilesetPreloadSystem.new()
    local system = Systems.SetupSystem.new()
    setmetatable(system, LDtkTilesetPreloadSystem)
    return system
end

---@param ecs table
---@return LDtkTilesetPreloadSystem
function LDtkTilesetPreloadSystem:init(ecs)
    Systems.SetupSystem.init(self, ecs)
    return self
end

function LDtkTilesetPreloadSystem:run()
    local ldtk = LDtkManager.getInstance()
    local tilesetPaths = ldtk:getAllTilesetPaths()

    for _, path in ipairs(tilesetPaths) do
        TextureManager.loadTexture(path)
    end
end

return LDtkTilesetPreloadSystem
