-- ECS/systems.lua
-- Base classes for different system types

local Systems = {}

---@class BaseSystem
---@field ecs table ECS instance
Systems.BaseSystem = {}
Systems.BaseSystem.__index = Systems.BaseSystem

---@return BaseSystem
function Systems.BaseSystem.new()
    local system = {}
    setmetatable(system, Systems.BaseSystem)
    return system
end

---@param ecs table
---@return BaseSystem
function Systems.BaseSystem:init(ecs)
    self.ecs = ecs
    return self
end

---@class SetupSystem : BaseSystem
---@field run fun(self: SetupSystem)
Systems.SetupSystem = setmetatable({}, {__index = Systems.BaseSystem})
Systems.SetupSystem.__index = Systems.SetupSystem

function Systems.SetupSystem:run()
    -- Override this method in derived classes
    error("SetupSystem:run() not implemented")
end

---@return SetupSystem
function Systems.SetupSystem.new()
    ---@type BaseSystem
    local system = Systems.BaseSystem.new()
    ---@cast system SetupSystem
    setmetatable(system, Systems.SetupSystem)
    return system
end

---@class UpdateSystem : BaseSystem
---@field run fun(self: UpdateSystem, dt: number)
Systems.UpdateSystem = setmetatable({}, {__index = Systems.BaseSystem})
Systems.UpdateSystem.__index = Systems.UpdateSystem

---@param _ number dt parameter, not used in base class
function Systems.UpdateSystem:run(_)
    -- Override this method in derived classes
    error("UpdateSystem:run(dt) not implemented")
end

---@return UpdateSystem
function Systems.UpdateSystem.new()
    ---@type BaseSystem
    local system = Systems.BaseSystem.new()
    ---@cast system UpdateSystem
    setmetatable(system, Systems.UpdateSystem)
    return system
end

---@class RenderSystem : BaseSystem
---@field run fun(self: RenderSystem, renderer: table)
Systems.RenderSystem = setmetatable({}, {__index = Systems.BaseSystem})
Systems.RenderSystem.__index = Systems.RenderSystem

---@param _ table renderer parameter, not used in base class
function Systems.RenderSystem:run(_)
    -- Override this method in derived classes
    error("RenderSystem:run(renderer) not implemented")
end

---@return RenderSystem
function Systems.RenderSystem.new()
    ---@type BaseSystem
    local system = Systems.BaseSystem.new()
    ---@cast system RenderSystem
    setmetatable(system, Systems.RenderSystem)
    return system
end

---@class EventSystem : BaseSystem
---@field run fun(self: EventSystem, event: table)
Systems.EventSystem = setmetatable({}, {__index = Systems.BaseSystem})
Systems.EventSystem.__index = Systems.EventSystem

---@param _ table event parameter, not used in base class
function Systems.EventSystem:run(_)
    -- Override this method in derived classes
    error("EventSystem:run(event) not implemented")
end

---@return EventSystem
function Systems.EventSystem.new()
    ---@type BaseSystem
    local system = Systems.BaseSystem.new()
    ---@cast system EventSystem
    setmetatable(system, Systems.EventSystem)
    return system
end

return Systems
