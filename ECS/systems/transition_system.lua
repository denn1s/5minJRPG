-- ECS/systems/transition_system.lua
-- System for handling scene transitions

local Systems = require("ECS.systems")
local Transition = require("ECS.transition")

---@class TransitionSystem : UpdateSystem
---@field sceneManager table Scene manager instance
---@field active boolean Whether the system is active
local TransitionSystem = setmetatable({}, {__index = Systems.UpdateSystem})
TransitionSystem.__index = TransitionSystem

---@return TransitionSystem
function TransitionSystem.new()
    local system = Systems.UpdateSystem.new()
    setmetatable(system, TransitionSystem)
    system.active = true
    return system
end

---@param ecs table
---@param sceneManager table
---@return TransitionSystem
function TransitionSystem:init(ecs, sceneManager)
    Systems.UpdateSystem.init(self, ecs)
    self.sceneManager = sceneManager
    -- This system always runs, even when input is locked
    self.ignoreInputLock = true
    return self
end

---@param dt number Delta time
function TransitionSystem:run(dt)
    if not self.active then return end
    
    -- Update the transition state
    Transition:update(dt, self.sceneManager)
end

return TransitionSystem
