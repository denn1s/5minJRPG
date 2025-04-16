-- ECS/core/debug_system.lua
-- Debug system for displaying information about the game state

local Systems = require("ECS.systems")

---@class DebugSystem : RenderSystem
---@field ecs table ECS instance
---@field showDebugInfo boolean Whether to show debug information
---@field debugInterval number Time interval for updating debug info (in seconds)
---@field timeElapsed number Time elapsed since last debug info update
---@field sceneManager table Scene manager instance
---@field lastLogTime number Time of last console log
local DebugSystem = setmetatable({}, {__index = Systems.RenderSystem})
DebugSystem.__index = DebugSystem

---@return DebugSystem
function DebugSystem.new()
    local system = Systems.RenderSystem.new()
    setmetatable(system, DebugSystem)
    system.showDebugInfo = false -- Off by default
    system.debugInterval = 1.0   -- Log every second
    system.timeElapsed = 0
    system.lastLogTime = 0
    return system
end

---@param ecs table
---@param sceneManager table Scene manager instance
---@return DebugSystem
function DebugSystem:init(ecs, sceneManager)
    Systems.RenderSystem.init(self, ecs)
    self.sceneManager = sceneManager
    return self
end

-- Gather debug information and return as a table of strings
function DebugSystem:gatherDebugInfo()
    local debugInfo = {}
    
    -- System time
    table.insert(debugInfo, "Time: " .. os.date("%H:%M:%S"))
    
    -- Get level information
    if self.sceneManager and self.sceneManager.activeScene then
        table.insert(debugInfo, "Level: " .. self.sceneManager.activeScene.name)
        
        -- Count entities
        local entityCount = 0
        for _, _ in pairs(self.ecs.entities) do
            entityCount = entityCount + 1
        end
        
        table.insert(debugInfo, "Entities: " .. entityCount)
    else
        table.insert(debugInfo, "No active scene")
    end
    
    -- Get world information
    if self.sceneManager and self.sceneManager.activeScene then
        local world = self.sceneManager.activeScene.world
        if world then
            table.insert(debugInfo, string.format("World: %dx%d", world.width, world.height))
            
            -- Get world type if available
            local worldType = world:getProperty("type")
            if worldType then
                table.insert(debugInfo, "World type: " .. worldType)
            end
        end
    end
    
    -- Get camera information
    if self.sceneManager and self.sceneManager.activeScene then
        local camera = self.sceneManager.activeScene.camera
        if camera then
            table.insert(debugInfo, string.format("Camera: x=%d, y=%d, width=%d, height=%d", 
                math.floor(camera.x), 
                math.floor(camera.y), 
                camera.width, 
                camera.height))
        end
    end
    
    -- Get player information
    local playerEntities = self.ecs:getEntitiesWithComponent("player")
    if #playerEntities > 0 then
        local player = playerEntities[1]
        local transform = player:getComponent("transform")
        local velocity = player:getComponent("velocity")
        
        if transform then
            local playerInfo = string.format("Player: x=%d, y=%d", 
                math.floor(transform.x), 
                math.floor(transform.y))
                
            if velocity then
                playerInfo = playerInfo .. string.format(", dx=%.1f, dy=%.1f", 
                    velocity.dx, 
                    velocity.dy)
            end
            
            table.insert(debugInfo, playerInfo)
        end
    end
    
    return debugInfo
end

-- Log debug information to console
function DebugSystem:logDebugInfo()
    local debugInfo = self:gatherDebugInfo()
    
    print("\n=== DEBUG INFO ===")
    for _, line in ipairs(debugInfo) do
        print(line)
    end
    print("=================")
end

---@param renderer table
function DebugSystem:run(_)
    if not self.showDebugInfo then
        return
    end
    
    -- Only log at certain intervals to avoid console spam
    local currentTime = love.timer.getTime()
    if currentTime - self.lastLogTime >= self.debugInterval then
        self.lastLogTime = currentTime
        self:logDebugInfo()
    end
end

-- Toggle debug information display
function DebugSystem:toggleDebugInfo()
    self.showDebugInfo = not self.showDebugInfo
    print("Debug info logging: " .. (self.showDebugInfo and "ON" or "OFF"))
    
    -- Log immediately when turned on
    if self.showDebugInfo then
        self:logDebugInfo()
    end
end

return DebugSystem
