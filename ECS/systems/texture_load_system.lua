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
    -- Debug: Print all entities first
    print("\n=== TextureLoadSystem Debug ===")
    print("Total entities in ECS: " .. self:countEntities())

    -- Debug: Print all component types in the ECS
    self:printAllComponentTypes()

    -- Debug: Check cache directly
    if self.ecs.entityComponentCache and self.ecs.entityComponentCache["texture"] then
        print("Entities in texture cache: " .. self:countTableEntries(self.ecs.entityComponentCache["texture"]))
    else
        print("No entities in texture cache or cache doesn't exist!")
    end

    -- Get all entities with texture components
    local entities = self.ecs:getEntitiesWithComponent("texture")

    print("TextureLoadSystem: Found " .. #entities .. " entities with texture components")

    -- If no entities found, try to manually identify entities with texture components
    if #entities == 0 then
        print("Attempting manual entity search...")
        self:findEntitiesWithTextureManually()
    end

    for _, entity in ipairs(entities) do
        local texture = entity:getComponent("texture")

        -- Only load if the path is valid
        if texture and texture.path and texture.path ~= "" then
            print("TextureLoadSystem: Loading texture for entity " .. entity.id .. ": " .. texture.path)

            -- Use the texture manager to load the texture
            local textureData, width, height = TextureManager.loadTexture(texture.path)

            -- Update the texture component with metadata
            -- Note: We don't store the actual texture data in the component
            -- That remains in the texture manager's cache
            texture.width = width
            texture.height = height
            texture.loaded = width > 0 and height > 0

            if texture.loaded then
                print("TextureLoadSystem: Successfully loaded texture for entity " .. entity.id ..
                      " (" .. width .. "x" .. height .. ")")
            else
                print("TextureLoadSystem: Failed to load texture for entity " .. entity.id)
            end
        else
            print("TextureLoadSystem: Entity " .. entity.id .. " has invalid texture path")
        end
    end

    print("=== TextureLoadSystem Debug End ===\n")
end

-- Helper function to count entities
function TextureLoadSystem:countEntities()
    local count = 0
    for _, _ in pairs(self.ecs.entities) do
        count = count + 1
    end
    return count
end

-- Helper function to count table entries
function TextureLoadSystem:countTableEntries(tbl)
    if not tbl then return 0 end
    local count = 0
    for _, _ in pairs(tbl) do
        count = count + 1
    end
    return count
end

-- Helper function to print all component types
function TextureLoadSystem:printAllComponentTypes()
    print("Component types in cache:")
    if not self.ecs.entityComponentCache then
        print("  No component cache found!")
        return
    end

    local types = {}
    for compType, _ in pairs(self.ecs.entityComponentCache) do
        table.insert(types, compType)
    end

    if #types == 0 then
        print("  No component types in cache!")
    else
        print("  " .. table.concat(types, ", "))
    end
end

-- Helper function to manually find entities with texture components
function TextureLoadSystem:findEntitiesWithTextureManually()
    print("Manually searching for entities with texture components...")
    local found = 0

    for id, entity in pairs(self.ecs.entities) do
        print("Checking entity " .. id)
        for compName, component in pairs(entity.components) do
            print("  Has component: " .. compName)
            if compName == "texture" then
                found = found + 1
                print("  FOUND texture component on entity " .. id .. "!")

                -- Try to load the texture
                if component.path and component.path ~= "" then
                    print("  Loading texture: " .. component.path)
                    local _, width, height = TextureManager.loadTexture(component.path)
                    component.width = width
                    component.height = height
                    component.loaded = width > 0 and height > 0
                    print("  Loaded: " .. (component.loaded and "Yes" or "No"))
                else
                    print("  Invalid path in texture component")
                end
            end
        end
    end

    print("Manual search found " .. found .. " entities with texture components")
end

return TextureLoadSystem
