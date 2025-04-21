-- ECS/scene.lua
-- Scene for the ECS

---@class Scene
---@field name string Name of the scene
---@field systems table<string, table> Systems in this scene organized by type
---@field initialized boolean Whether the scene has been initialized
---@field camera Camera Camera for this scene
---@field world World World for this scene

-- Scene class definition
---@class Scene
local Scene = {}
Scene.__index = Scene

---@param name string Name of the scene
---@return Scene
function Scene.new(name)
    local scene = {
        name = name,
        systems = {
            setup = {},
            update = {},
            render = {},
            event = {}
        },
        initialized = false,
        world = nil,  -- Will be set by initWorld
        camera = nil,  -- Will be set by initCamera
        levelId = nil,  -- Will be set when a level is loaded
    }
    setmetatable(scene, Scene)
    return scene
end

-- Add a system to the scene
---@param systemType string
---@param system table
---@return Scene
function Scene:addSystem(systemType, system)
    if not self.systems[systemType] then
        error("Unknown system type: " .. systemType)
    end

    table.insert(self.systems[systemType], system)
    return self
end

return Scene
