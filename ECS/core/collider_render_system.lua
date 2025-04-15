-- ECS/core/collider_render_system.lua
-- System for rendering collider debugging visuals

local Systems = require("ECS.systems")

---@class ColliderRenderSystem : RenderSystem
---@field ecs table ECS instance
local ColliderRenderSystem = setmetatable({}, {__index = Systems.RenderSystem})
ColliderRenderSystem.__index = ColliderRenderSystem

---@return ColliderRenderSystem
function ColliderRenderSystem.new()
    local system = Systems.RenderSystem.new()
    setmetatable(system, ColliderRenderSystem)
    return system
end

---@param ecs table
---@return ColliderRenderSystem
function ColliderRenderSystem:init(ecs)
    Systems.RenderSystem.init(self, ecs)
    return self
end

---@param renderer table
function ColliderRenderSystem:run(renderer)
    -- Get all entities with both transform and collider components
    local entities = self.ecs:getEntitiesWithComponent("collider")

    for _, entity in ipairs(entities) do
        local transform = entity:getComponent("transform")
        local collider = entity:getComponent("collider")

        -- Only render if both components exist and debugging is enabled
        if transform and collider and collider.debug then
            -- Calculate collider position with offset
            local x = transform.x + collider.offsetX
            local y = transform.y + collider.offsetY

            -- Draw the collider outline
            -- Use the second color (dark color) for visibility
            renderer:draw_rectangle(
                x,
                y,
                collider.width,
                collider.height,
                2,  -- Color index 2 (dark color)
                false  -- Not filled
            )
        end
    end
end

return ColliderRenderSystem
