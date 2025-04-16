-- ECS/ldtk/ldtk_system.lua
-- System for loading and handling LDtk maps

local Systems = require("ECS.systems")
local LDtkParser = require("ECS.ldtk.ldtk_parser")
local Components = require("ECS.components")

---@class LDtkLoadSystem : SetupSystem
---@field ecs table ECS instance
---@field ldtkParser LDtkParser The LDtk parser instance
---@field currentLevel string Current level identifier
---@field mapFilePath string Path to the LDtk map file
local LDtkLoadSystem = setmetatable({}, {__index = Systems.SetupSystem})
LDtkLoadSystem.__index = LDtkLoadSystem

---@return LDtkLoadSystem
function LDtkLoadSystem.new()
    local system = Systems.SetupSystem.new()
    setmetatable(system, LDtkLoadSystem)
    system.currentLevel = nil
    system.mapFilePath = nil
    return system
end

---@param ecs table
---@param mapFilePath string Path to the LDtk map file
---@param initialLevel string|nil Initial level to load (defaults to the first level)
---@return LDtkLoadSystem
function LDtkLoadSystem:init(ecs, mapFilePath, initialLevel)
    Systems.SetupSystem.init(self, ecs)
    self.mapFilePath = mapFilePath
    self.currentLevel = initialLevel
    self.ldtkParser = LDtkParser.new(mapFilePath)
    return self
end

function LDtkLoadSystem:run()
    if not self.ldtkParser:load() then
        print("Failed to load LDtk map")
        return
    end
    
    -- Print basic map info
    self.ldtkParser:printInfo()
    
    -- If no specific level was provided, use "Level_1" as the starting point
    if not self.currentLevel then
        self.currentLevel = "Level_1"  -- Start in the house
    end
    
    if self.currentLevel then
        -- Print info about the initial level
        print("Loading initial level: " .. self.currentLevel)
        self.ldtkParser:printLevelLayers(self.currentLevel)
        
        -- Actually load the level
        -- Default player position converted from grid coordinates to world coordinates
        -- For Level_1, we start at position (65, 14)
        self:loadLevel(self.currentLevel, 65, 14)
    else
        print("No levels found in the LDtk map")
    end
end

---Load a specific level from the LDtk map
---@param levelIdentifier string Level identifier
---@param playerX number|nil Initial player X position (grid coordinates)
---@param playerY number|nil Initial player Y position (grid coordinates)
function LDtkLoadSystem:loadLevel(levelIdentifier, playerX, playerY)
    local level = self.ldtkParser:getLevel(levelIdentifier)
    if not level then
        print("Level not found: " .. levelIdentifier)
        return
    end
    
    print("Loading level: " .. levelIdentifier)
    
    -- Create a tilemap system to process the level data
    local TilemapSystem = require("ECS.ldtk.ldtk_tilemap_system")
    local tilemapSystem = TilemapSystem.new():init(self.ecs, self.ldtkParser, level)
    
    -- Run the tilemap system to create entities for this level
    tilemapSystem:run()
    
    -- Update current level
    self.currentLevel = levelIdentifier
    
    -- Store level data for tilemap rendering
    self.levelData = level
    
    -- Position the player if coordinates are provided
    if playerX and playerY then
        self:positionPlayer(playerX, playerY)
    end
    
    -- Return the level data for the rendering system
    return level
end

---Get the current level data
---@return table|nil Level data or nil if no level is loaded
function LDtkLoadSystem:getLevelData()
    return self.levelData
end

---Get the LDtk parser
---@return table LDtk parser
function LDtkLoadSystem:getParser()
    return self.ldtkParser
end

---Position the player entity at the specified grid coordinates
---@param gridX number Grid X coordinate
---@param gridY number Grid Y coordinate
function LDtkLoadSystem:positionPlayer(gridX, gridY)
    -- Find the player entity
    local playerEntities = self.ecs:getEntitiesWithComponent("player")
    
    -- Get the grid size from the LDtk data
    local gridSize = 8  -- Default to 8x8 if not found
    if self.ldtkParser.data and self.ldtkParser.data.defaultGridSize then
        gridSize = self.ldtkParser.data.defaultGridSize
    end
    
    -- Convert grid coordinates to world coordinates
    local worldX = gridX * gridSize
    local worldY = gridY * gridSize
    
    for _, entity in ipairs(playerEntities) do
        local transform = entity:getComponent("transform")
        if transform then
            transform.x = worldX
            transform.y = worldY
            print(string.format("Positioned player at grid (%d, %d) -> world (%d, %d)", 
                gridX, gridY, worldX, worldY))
            
            -- If there's a camera system, tell it to center on the player
            local sceneManager = require("ECS.scene_manager").SceneManager
            if sceneManager and sceneManager.activeScene and sceneManager.activeScene.camera then
                sceneManager.activeScene.camera:centerOn(worldX, worldY)
                print(string.format("Centered camera on world position (%d, %d)", worldX, worldY))
            end
        end
    end
end

return LDtkLoadSystem
