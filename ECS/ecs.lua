-- ECS/ecs.lua
-- Core implementation of Entity Component System

---@class Entity
---@field id number Unique entity identifier
---@field components table<string, table> Components attached to this entity
---@field addComponent fun(self: Entity, component: table): Entity
---@field removeComponent fun(self: Entity, componentName: string): Entity
---@field getComponent fun(self: Entity, componentName: string): table|nil
---@field hasComponent fun(self: Entity, componentName: string): boolean
---@field destroy fun(self: Entity)

---@class ECS
---@field entities table<number, Entity> All entities in the system
---@field nextEntityId number Next available entity ID
---@field components table Components by type
---@field systems table Systems categorized by type
---@field entityComponentCache table<string, table<number, Entity>> Cache for fast component lookup
local ECS = {
    entities = {},
    nextEntityId = 1,
    components = {},
    systems = {
        setup = {},
        update = {},
        render = {},
        event = {}
    },
    entityComponentCache = {} -- Cache for fast component lookup
}

-- Entity methods
---@return Entity
function ECS:createEntity()
    local entity = {
        id = self.nextEntityId,
        components = {}
    }

    -- Add methods to entity
    ---@param component table
    ---@return Entity
    function entity:addComponent(component)
        self.components[component.name] = component

        -- Update cache
        if not ECS.entityComponentCache[component.name] then
            ECS.entityComponentCache[component.name] = {}
        end
        ECS.entityComponentCache[component.name][self.id] = self

        return self
    end

    ---@param componentName string
    ---@return Entity
    function entity:removeComponent(componentName)
        if self.components[componentName] then
            self.components[componentName] = nil

            -- Update cache
            if ECS.entityComponentCache[componentName] then
                ECS.entityComponentCache[componentName][self.id] = nil
            end
        end

        return self
    end

    ---@param componentName string
    ---@return table|nil
    function entity:getComponent(componentName)
        return self.components[componentName]
    end

    ---@param componentName string
    ---@return boolean
    function entity:hasComponent(componentName)
        return self.components[componentName] ~= nil
    end

    function entity:destroy()
        -- Remove from all caches
        for componentName, _ in pairs(self.components) do
            if ECS.entityComponentCache[componentName] then
                ECS.entityComponentCache[componentName][self.id] = nil
            end
        end

        -- Remove from entities list
        ECS.entities[self.id] = nil
    end

    -- Add to entities list
    self.entities[entity.id] = entity
    self.nextEntityId = self.nextEntityId + 1

    return entity
end

-- Component creation function
---@param name string
---@param data? table
---@return table
function ECS:createComponent(name, data)
    local component = {
        name = name
    }

    -- Copy all data fields to the component
    if data then
        for k, v in pairs(data) do
            component[k] = v
        end
    end

    return component
end

-- Register systems
---@param systemType string
---@param system table
function ECS:registerSystem(systemType, system)
    if not self.systems[systemType] then
        error("Unknown system type: " .. systemType)
    end

    table.insert(self.systems[systemType], system)
end

-- Get entities with specific component
---@param componentName string
---@return Entity[]
function ECS:getEntitiesWithComponent(componentName)
    local result = {}

    -- Use cache for faster lookup
    if self.entityComponentCache[componentName] then
        for _, entity in pairs(self.entityComponentCache[componentName]) do
            table.insert(result, entity)
        end
    end

    return result
end

-- Run all systems of a specific type
---@param systemType string
function ECS:runSystems(systemType, ...)
    if not self.systems[systemType] then
        error("Unknown system type: " .. systemType)
    end

    for _, system in ipairs(self.systems[systemType]) do
        if system.run then
            system:run(...)
        end
    end
end

-- Initialize ECS
function ECS:init()
    self:runSystems("setup")
end

-- Update ECS
---@param dt number
function ECS:update(dt)
    self:runSystems("update", dt)
end

-- Render ECS
---@param renderer table
function ECS:render(renderer)
    self:runSystems("render", renderer)
end

-- Handle event
---@param event table
function ECS:handleEvent(event)
    self:runSystems("event", event)
end

return ECS
