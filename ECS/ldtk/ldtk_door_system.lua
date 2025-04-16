-- ECS/ldtk/ldtk_door_system.lua
-- System for handling door interactions in LDtk maps

local Systems = require("ECS.systems")
local Transition = require("ECS.transition")

---@class LDtkDoorSystem : UpdateSystem
---@field ecs table ECS instance
---@field ldtkLoadSystem table LDtk load system
---@field doors table<string, table> Cache of door entities indexed by position
---@field interactionDistance number Distance at which player can interact with doors
---@field cooldown number Time between door interactions
---@field cooldownTimer number Timer for interaction cooldown
local LDtkDoorSystem = setmetatable({}, {__index = Systems.UpdateSystem})
LDtkDoorSystem.__index = LDtkDoorSystem

---@return LDtkDoorSystem
function LDtkDoorSystem.new()
    local system = Systems.UpdateSystem.new()
    setmetatable(system, LDtkDoorSystem)
    system.doors = {}
    system.interactionDistance = 16  -- Interaction distance in pixels
    system.cooldown = 0.5            -- Cooldown time in seconds
    system.cooldownTimer = 0
    return system
end

---@param ecs table
---@param ldtkLoadSystem table LDtk load system
---@return LDtkDoorSystem
function LDtkDoorSystem:init(ecs, ldtkLoadSystem)
    Systems.UpdateSystem.init(self, ecs)
    self.ldtkLoadSystem = ldtkLoadSystem
    return self
end

-- Cache door positions from the current level
function LDtkDoorSystem:cacheDoors()
    self.doors = {}
    
    local level = self.ldtkLoadSystem:getLevelData()
    if not level or not level.layerInstances then
        return
    end
    
    -- Find the Doors layer
    for _, layer in ipairs(level.layerInstances) do
        if layer.__identifier == "Doors" and layer.entityInstances then
            for _, entity in ipairs(layer.entityInstances) do
                if entity.__identifier == "Door" then
                    local px, py = entity.px[1], entity.px[2]
                    
                    -- Extract door data
                    local doorData = {
                        position = {x = px, y = py},
                        size = {width = entity.width, height = entity.height},
                        targetLevel = nil,
                        targetX = nil,
                        targetY = nil
                    }
                    
                    -- Process door fields
                    if entity.fieldInstances then
                        for _, field in ipairs(entity.fieldInstances) do
                            if field.__identifier == "To" then
                                doorData.targetLevel = field.__value
                            elseif field.__identifier == "x" then
                                doorData.targetX = field.__value
                            elseif field.__identifier == "y" then
                                doorData.targetY = field.__value
                            end
                        end
                    end
                    
                    -- Cache the door at its position
                    local key = string.format("%d,%d", px, py)
                    self.doors[key] = doorData
                    
                    print(string.format("Cached door at (%d, %d) to level %s at (%d, %d)",
                        px, py, 
                        doorData.targetLevel or "unknown",
                        doorData.targetX or 0,
                        doorData.targetY or 0))
                end
            end
            
            print("Cached " .. #layer.entityInstances .. " doors in level " .. self.ldtkLoadSystem.currentLevel)
            break
        end
    end
end

-- Check if the player is near a door
---@param playerX number Player's X position
---@param playerY number Player's Y position
---@return table|nil Door data if player is near a door, nil otherwise
function LDtkDoorSystem:findNearbyDoor(playerX, playerY)
    for _, door in pairs(self.doors) do
        local dx = playerX - door.position.x
        local dy = playerY - door.position.y
        local distance = math.sqrt(dx*dx + dy*dy)
        
        if distance <= self.interactionDistance then
            return door
        end
    end
    
    return nil
end

---@param dt number Delta time
function LDtkDoorSystem:run(dt)
    -- Update cooldown timer
    if self.cooldownTimer > 0 then
        self.cooldownTimer = self.cooldownTimer - dt
    end
    
    -- Check if we have an active transition
    if Transition.active then
        return
    end
    
    -- Cache doors if we don't have any
    if next(self.doors) == nil then
        self:cacheDoors()
    end
    
    -- Get player entity
    local playerEntities = self.ecs:getEntitiesWithComponent("player")
    if #playerEntities == 0 then
        return
    end
    
    local player = playerEntities[1]
    local transform = player:getComponent("transform")
    if not transform then
        return
    end
    
    -- Check for door interaction
    if love.keyboard.isDown("return") or love.keyboard.isDown("space") or love.keyboard.isDown("e") then
        if self.cooldownTimer <= 0 then
            local nearbyDoor = self:findNearbyDoor(transform.x, transform.y)
            
            if nearbyDoor and nearbyDoor.targetLevel then
                self.cooldownTimer = self.cooldown
                
                print(string.format("Using door to level %s at (%d, %d)",
                    nearbyDoor.targetLevel,
                    nearbyDoor.targetX or 0,
                    nearbyDoor.targetY or 0))
                
                -- Transition to the new level
                Transition:start("fade_out", nearbyDoor.targetLevel, false, 0.5)
                
                -- Store target coordinates for when transition completes
                self.pendingLevelChange = {
                    targetLevel = nearbyDoor.targetLevel,
                    targetX = nearbyDoor.targetX,
                    targetY = nearbyDoor.targetY
                }
            end
        end
    end
    
    -- Check if we need to complete a level transition after fade out
    if self.pendingLevelChange and not Transition.active and Transition.type == "none" then
        -- Get the LDtk tilemap render system
        local SceneManager = require("ECS.scene_manager").SceneManager
        
        if SceneManager.activeScene then
            -- Find the tilemap render system
            for _, system in ipairs(SceneManager.activeScene.systems.render) do
                if system.__index == require("ECS.ldtk.ldtk_tilemap_render_system").__index then
                    -- Update the system's level
                    system:setLevel(self.pendingLevelChange.targetLevel)
                    break
                end
            end
        end
        
        -- Load the new level
        self.ldtkLoadSystem:loadLevel(
            self.pendingLevelChange.targetLevel,
            self.pendingLevelChange.targetX,
            self.pendingLevelChange.targetY
        )
        
        -- Clear the pending level change
        self.pendingLevelChange = nil
        
        -- Clear the door cache for the new level
        self.doors = {}
    end
end

return LDtkDoorSystem
