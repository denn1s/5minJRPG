-- ECS/systems/texture_load_system.lua
-- System responsible for loading textures for any entity with a texture component

local Systems = require("ECS.systems")
local TextureManager = require("ECS.texture_manager")

---@class TextureLoadSystem : SetupSystem
---@field ecs table ECS instance
local TextureLoadSystem = setmetatable({}, {__index = Systems.SetupSystem})
TextureLoadSystem.__index = TextureLoadSystem

---@return TextureLoadSystem
function TextureLoadSystem.new()
    local system = Systems.SetupSystem.new()
    setmetatable(system, TextureLoadSystem)
    return system
end

---@param ecs table
---@return TextureLoadSystem
function TextureLoadSystem:init(ecs)
    Systems.SetupSystem.init(self, ecs)
    return self
end

function TextureLoadSystem:run()
    local entities = self.ecs:getEntitiesWithComponent("texture")

    for _, entity in ipairs(entities) do
        local texture = entity:getComponent("texture")

        if texture and texture.path and texture.path ~= "" then
            print("[TextureLoadSystem] Loading texture for entity " .. entity.id .. ": " .. texture.path)

            -- Use the texture manager to load the texture
            local _, width, height = TextureManager.loadTexture(texture.path)

            -- Update the texture component with metadata
            -- Note: We don't store the actual texture data in the component
            -- That remains in the texture manager's cache
            texture.width = width
            texture.height = height
            texture.loaded = width > 0 and height > 0

            if texture.loaded then
                print("[TextureLoadSystem] Successfully loaded texture for entity " .. entity.id ..
                      " (" .. width .. "x" .. height .. ")")
            else
                print("[TextureLoadSystem] Failed to load texture for entity " .. entity.id)
            end
        else
            print("[TextureLoadSystem] Entity " .. entity.id .. " has invalid texture path")
        end
    end
end

return TextureLoadSystem
