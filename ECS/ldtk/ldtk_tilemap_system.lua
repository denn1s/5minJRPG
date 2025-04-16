-- ECS/ldtk/ldtk_tilemap_system.lua
-- System for converting LDtk tiles into game entities

local Systems = require("ECS.systems")
local Components = require("ECS.components")
local TextureManager = require("ECS.texture_manager")

---@class LDtkTilemapSystem : SetupSystem
---@field ecs table ECS instance
---@field ldtkParser table The LDtk parser instance
---@field levelData table Current level data
local LDtkTilemapSystem = setmetatable({}, {__index = Systems.SetupSystem})
LDtkTilemapSystem.__index = LDtkTilemapSystem

---@return LDtkTilemapSystem
function LDtkTilemapSystem.new()
    local system = Systems.SetupSystem.new()
    setmetatable(system, LDtkTilemapSystem)
    return system
end

---@param ecs table
---@param ldtkParser table
---@param levelData table
---@return LDtkTilemapSystem
function LDtkTilemapSystem:init(ecs, ldtkParser, levelData)
    Systems.SetupSystem.init(self, ecs)
    self.ldtkParser = ldtkParser
    self.levelData = levelData
    return self
end

-- Convert a hex color string to RGB values (0-1 range)
---@param hexColor string Hex color string (e.g., "#FF5500")
---@return number, number, number r, g, b values (0-1 range)
local function hexToRGB(hexColor)
    if not hexColor or hexColor:sub(1, 1) ~= "#" then
        return 1, 1, 1  -- Default to white if invalid
    end
    
    local hex = hexColor:sub(2)
    local r = tonumber(hex:sub(1, 2), 16) or 255
    local g = tonumber(hex:sub(3, 4), 16) or 255
    local b = tonumber(hex:sub(5, 6), 16) or 255
    
    return r/255, g/255, b/255
end

function LDtkTilemapSystem:run()
    if not self.levelData or not self.levelData.layerInstances then
        print("LDtkTilemapSystem: No level data provided")
        return
    end
    
    -- Process all layers from bottom to top (reverse order from LDtk)
    for i = #self.levelData.layerInstances, 1, -1 do
        local layer = self.levelData.layerInstances[i]
        self:processLayer(layer)
    end
    
    print("LDtkTilemapSystem: Processed level " .. self.levelData.identifier)
end

---Process a single layer from the LDtk level
---@param layer table The layer instance data
function LDtkTilemapSystem:processLayer(layer)
    local layerId = layer.__identifier
    local layerType = layer.__type
    
    print("Processing layer: " .. layerId .. " (" .. layerType .. ")")
    
    if layerType == "Tiles" then
        self:processTilesLayer(layer)
    elseif layerType == "IntGrid" then
        self:processIntGridLayer(layer)
    elseif layerType == "Entities" then
        self:processEntitiesLayer(layer)
    else
        print("Unsupported layer type: " .. layerType)
    end
end

---Process a Tiles layer
---@param layer table The layer instance data
function LDtkTilemapSystem:processTilesLayer(layer)
    -- For now, just print the number of tiles
    if not layer.gridTiles then
        print("  No tiles in this layer")
        return
    end
    
    print("  Found " .. #layer.gridTiles .. " tiles")
    
    -- TODO: Convert tiles to game entities
    -- This will be implemented in a future version
end

---Process an IntGrid layer
---@param layer table The layer instance data
function LDtkTilemapSystem:processIntGridLayer(layer)
    if not layer.intGridCsv then
        print("  No IntGrid data in this layer")
        return
    end
    
    local gridWidth = layer.__cWid
    local gridHeight = layer.__cHei
    local gridSize = layer.__gridSize
    
    print(string.format("  IntGrid dimensions: %dx%d (grid size: %d)", 
        gridWidth, gridHeight, gridSize))
    
    -- Count non-zero cells
    local walkableCells = 0
    for _, value in ipairs(layer.intGridCsv) do
        if value == 1 then  -- 1 is WALKABLE in your case
            walkableCells = walkableCells + 1
        end
    end
    
    print("  Found " .. walkableCells .. " walkable cells")
    
    -- TODO: Create collision entities for the IntGrid
    -- This will be implemented in a future version
end

---Process an Entities layer
---@param layer table The layer instance data
function LDtkTilemapSystem:processEntitiesLayer(layer)
    if not layer.entityInstances then
        print("  No entities in this layer")
        return
    end
    
    print("  Found " .. #layer.entityInstances .. " entities")
    
    for _, entity in ipairs(layer.entityInstances) do
        local entityId = entity.__identifier
        local px = entity.px
        
        if entityId == "Door" then
            self:processDoorEntity(entity)
        else
            print(string.format("    Unknown entity type: %s at position (%d, %d)", 
                entityId, px[1], px[2]))
        end
    end
end

---Process a Door entity
---@param entity table The entity instance data
function LDtkTilemapSystem:processDoorEntity(entity)
    local px, py = entity.px[1], entity.px[2]
    local width, height = entity.width, entity.height
    
    -- Find the fields
    local targetLevel = nil
    local targetX = nil
    local targetY = nil
    
    if entity.fieldInstances then
        for _, field in ipairs(entity.fieldInstances) do
            if field.__identifier == "To" then
                targetLevel = field.__value
            elseif field.__identifier == "x" then
                targetX = field.__value
            elseif field.__identifier == "y" then
                targetY = field.__value
            end
        end
    end
    
    print(string.format("    Door to %s at (%d, %d)", 
        targetLevel or "unknown", targetX or 0, targetY or 0))
    
    -- TODO: Create a door entity
    -- This will be implemented in a future version
end

return LDtkTilemapSystem
