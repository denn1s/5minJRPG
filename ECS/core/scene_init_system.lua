-- ECS/systems/scene_init_system.lua
-- System for initializing scene with a fade-in effect

local Systems = require("ECS.systems")
local Transition = require("ECS.transition")

---@class SceneInitSystem : SetupSystem
local SceneInitSystem = setmetatable({}, {__index = Systems.SetupSystem})
SceneInitSystem.__index = SceneInitSystem

---@return SceneInitSystem
function SceneInitSystem.new()
    local system = Systems.SetupSystem.new()
    setmetatable(system, SceneInitSystem)
    return system
end

---@param ecs table
---@param fadeIn boolean Whether to start with a fade-in effect
---@param duration number|nil Duration of the fade-in effect
---@return SceneInitSystem
function SceneInitSystem:init(ecs, fadeIn, duration)
    Systems.SetupSystem.init(self, ecs)
    self.fadeIn = fadeIn or false
    self.duration = duration or 0.5
    return self
end

function SceneInitSystem:run()
    -- Start with a fade-in effect if requested
    if self.fadeIn then
        Transition:start("fade_in", nil, false, self.duration)
    end
end

return SceneInitSystem
