-- ECS/scene_manager.lua
-- Scene management system for the ECS

local Transition = require("ECS.transition")
local Camera = require("ECS.camera")
local World = require("ECS.world")
local LDtkManager = require("ECS.ldtk.ldtk_manager")
local WorldManager = require("ECS.world_manager")

---@class SceneState
---@field entities table[] Entities in this scene
---@field initialized boolean Whether the scene has been initialized
---@field cameraX number Camera X position
---@field cameraY number Camera Y position

---@class Scene
---@field name string Name of the scene
---@field systems table<string, table> Systems in this scene organized by type
---@field initialized boolean Whether the scene has been initialized
---@field camera Camera Camera for this scene
---@field world World World for this scene

---@class SceneManager
---@field scenes table<string, Scene> All registered scenes
---@field activeScene Scene|nil Currently active scene (can be nil)
---@field previousScene Scene|nil Previously active scene (can be nil)
---@field sceneStates table<string, SceneState> Preserved state for each scene
---@field persistentEntities table<number, table> Entities that persist across scene transitions
---@field ecs table The ECS instance
local SceneManager = {
    scenes = {},          -- All registered scenes
    activeScene = nil,    -- Currently active scene
    previousScene = nil,  -- Previously active scene (for returning)
    sceneStates = {},     -- Preserved state for each scene
    persistentEntities = {} -- Entities that persist across scene transitions
}

-- Scene class definition
---@class Scene
local Scene = {}
Scene.__index = Scene

---@param name string Name of the scene
---@param viewportWidth number Width of the viewport
---@param viewportHeight number Height of the viewport
---@param cameraX? number Initial camera X position (optional, defaults to 0)
---@param cameraY? number Initial camera Y position (optional, defaults to 0)
---@return Scene
function Scene.new(name, viewportWidth, viewportHeight, cameraX, cameraY)
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
        camera = Camera.new(viewportWidth, viewportHeight, cameraX or 0, cameraY or 0),
        levelId = nil  -- Will be set when a level is loaded
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

-- Initialize the scene manager with an ECS instance
---@param ecs table
---@param viewportWidth number
---@param viewportHeight number
---@return SceneManager
function SceneManager:init(ecs, viewportWidth, viewportHeight)
    self.ecs = ecs
    self.viewportWidth = viewportWidth
    self.viewportHeight = viewportHeight

    -- Add the transition system
    local TransitionSystem = require("ECS.core.transition_system")
    self.transitionSystem = TransitionSystem.new():init(ecs, self)

    return self
end

-- Register a new scene
---@param scene Scene
---@return SceneManager
function SceneManager:registerScene(scene)
    if self.scenes[scene.name] then
        error("Scene already registered: " .. scene.name)
    end

    self.scenes[scene.name] = scene
    self.sceneStates[scene.name] = {
        entities = {},
        initialized = false,
        cameraX = 0,
        cameraY = 0
    }

    return self
end

-- Create a new scene and register it
---@param name string
---@param viewportWidth number
---@param viewportHeight number
---@param cameraX? number Initial camera X position
---@param cameraY? number Initial camera Y position
---@return Scene
function SceneManager:createScene(name, viewportWidth, viewportHeight, cameraX, cameraY)
    local scene = Scene.new(name, viewportWidth, viewportHeight, cameraX, cameraY)
    self:registerScene(scene)
    return scene
end

-- Initialize the world for a scene from an LDtk level
---@param scene Scene The scene to initialize the world for
---@param levelId string LDtk level identifier
---@return World The created world
function SceneManager:initWorldFromLDtk(scene, levelId)
    -- Get the LDtk manager instance
    local ldtk = LDtkManager.getInstance()
    
    -- Get the world manager instance
    local worldManager = WorldManager.getInstance()
    
    -- Get the level data for the specified level ID
    local level = ldtk:getLevel(levelId)
    if not level then
        error("Level not found: " .. levelId)
    end
    
    -- Determine grid size (use LDtk's grid size)
    local gridSize = ldtk:getGridSize()
    
    -- Get width and height in grid cells
    local gridWidth = level.__cWid or 0
    local gridHeight = level.__cHei or 0
    
    print(string.format("[SceneManager] Initializing world for scene %s, level %s (%dx%d grid with %dpx cells)",
                        scene.name, levelId, gridWidth, gridHeight, gridSize))
    
    -- Validate level dimensions
    if gridWidth <= 0 or gridHeight <= 0 then
        error(string.format("Invalid level dimensions: %dx%d", gridWidth, gridHeight))
    end
    
    -- Create a new world for this level
    local world = worldManager:createWorld(levelId, gridWidth, gridHeight, gridSize)
    print(string.format("[SceneManager] Created world with dimensions: %dx%d pixels",
                         world.pixelWidth, world.pixelHeight))
    
    -- Set as active world
    worldManager:setActiveWorld(world)
    
    -- Store level ID in world properties
    world:setProperty("levelId", levelId)
    
    -- Update scene properties
    scene.levelId = levelId
    scene.world = world
    
    -- Update LDtk renderer system if present
    for _, system in ipairs(scene.systems.render) do
        if system.__index == require("ECS.ldtk.ldtk_tilemap_render_system").__index then
            system.currentLevel = levelId
        end
    end
    
    -- Now that we have a world, properly position the camera
    -- Default to the center of the world if no specific position is set
    local centerX = math.floor(world.pixelWidth / 2 - scene.camera.width / 2)
    local centerY = math.floor(world.pixelHeight / 2 - scene.camera.height / 2)
    scene.camera:setPosition(scene.camera.x or centerX, scene.camera.y or centerY)
    
    print(string.format("[SceneManager] Camera positioned at (%d, %d) for scene %s",
                         scene.camera.x, scene.camera.y, scene.name))
    
    return world
end

-- Mark an entity as persistent (preserved across scene transitions)
---@param entity table
---@param isPersistent? boolean
---@return SceneManager
function SceneManager:markEntityAsPersistent(entity, isPersistent)
    if isPersistent == nil then isPersistent = true end
    self.persistentEntities[entity.id] = isPersistent and entity or nil
    return self
end

-- Check if an entity is persistent
---@param entity table
---@return boolean
function SceneManager:isEntityPersistent(entity)
    return self.persistentEntities[entity.id] ~= nil
end

-- Save the current scene state
function SceneManager:saveCurrentSceneState()
    if not self.activeScene then return end

    local sceneName = self.activeScene.name
    ---@type SceneState
    local state = self.sceneStates[sceneName]

    -- Store camera position
    state.cameraX = self.activeScene.camera.x
    state.cameraY = self.activeScene.camera.y

    -- Store all non-persistent entities
    state.entities = {}
    for _, entity in pairs(self.ecs.entities) do
        if not self:isEntityPersistent(entity) then
            -- Store entity and its components
            local entityData = {
                id = entity.id,
                components = {}
            }

            for _, component in pairs(entity.components) do
                -- Deep copy the component
                local componentCopy = {}
                for k, v in pairs(component) do
                    componentCopy[k] = v
                end
                entityData.components[component.name] = componentCopy
            end

            table.insert(state.entities, entityData)
        end
    end

    state.initialized = self.activeScene.initialized
end

-- Restore a scene state
---@param sceneName string
function SceneManager:restoreSceneState(sceneName)
    ---@type SceneState
    local state = self.sceneStates[sceneName]
    if not state then return end

    -- Restore camera position
    local scene = self.scenes[sceneName]
    if scene then
        scene.camera:setPosition(state.cameraX, state.cameraY)
    end

    -- Remove all non-persistent entities
    for _, entity in pairs(self.ecs.entities) do
        if not self:isEntityPersistent(entity) then
            entity:destroy()
        end
    end

    -- Restore entities from the saved state
    for _, entityData in ipairs(state.entities) do
        local entity = self.ecs:createEntity()

        -- Restore components
        for _, componentData in pairs(entityData.components) do
            entity:addComponent(componentData)
        end
    end

    -- Set the scene's initialized state
    if scene then
        scene.initialized = state.initialized
    end
end

-- Transition to a new scene with fade effect
---@param sceneName string
---@param preserveCurrentScene? boolean
---@param duration? number
---@return SceneManager
function SceneManager:transitionToSceneWithFade(sceneName, preserveCurrentScene, duration)
    if not self.scenes[sceneName] then
        error("Scene not registered: " .. sceneName)
    end

    -- Start a fade-out transition
    Transition:start("fade_out", sceneName, preserveCurrentScene, duration)

    return self
end

-- Transition to a scene immediately (no fade)
---@param sceneName string
---@param preserveCurrentScene? boolean
---@return SceneManager
function SceneManager:transitionToScene(sceneName, preserveCurrentScene)
    if not self.scenes[sceneName] then
        error("Scene not registered: " .. sceneName)
    end

    -- Save the current scene state if we have one
    if self.activeScene then
        self:saveCurrentSceneState()
    end

    -- Store the previous scene
    if preserveCurrentScene and self.activeScene then
        self.previousScene = self.activeScene
    end

    -- Set the new active scene
    self.activeScene = self.scenes[sceneName]

    -- IMPORTANT: Immediately run setup systems to ensure proper initialization
    -- This ensures all resources are loaded before first render
    self:runSetupSystems()

    -- Restore the scene state
    self:restoreSceneState(sceneName)

    -- Mark as initialized after running setup and restoring state
    self.activeScene.initialized = true

    -- Make sure camera is within world bounds, if a world exists
    if self.activeScene.world then
        self.activeScene.camera:setPosition(
            self.activeScene.camera.x,
            self.activeScene.camera.y
        )
    end

    -- Call the onActivated callback if it exists
    if self.activeScene.onActivated then
        self.activeScene:onActivated()
    end

    return self
end

-- Return to the previous scene with fade effect
---@param duration? number
---@return SceneManager
function SceneManager:returnToPreviousSceneWithFade(duration)
    if not self.previousScene then
        return self
    end

    -- Start a fade-out transition to the previous scene
    Transition:start("fade_out", self.previousScene.name, false, duration)

    return self
end

-- Return to the previous scene immediately (no fade)
---@return SceneManager
function SceneManager:returnToPreviousScene()
    if not self.previousScene then
        return self
    end

    -- Swap active and previous scenes
    local tempScene = self.activeScene
    self.activeScene = self.previousScene
    self.previousScene = tempScene

    -- Restore the scene state
    self:restoreSceneState(self.activeScene.name)

    return self
end

-- Run setup systems for the active scene
function SceneManager:runSetupSystems()
    if not self.activeScene then return end

    for _, system in ipairs(self.activeScene.systems.setup) do
        if system.run then
            system:run()
        end
    end
end

-- Run update systems for the active scene
---@param dt number
function SceneManager:update(dt)
    -- Always update the transition system first
    if self.transitionSystem then
        self.transitionSystem:run(dt)
    end

    if not self.activeScene then return end

    for _, system in ipairs(self.activeScene.systems.update) do
        if system.run then
            -- Only run other update systems if input is not locked
            if not Transition:isInputLocked() or system.ignoreInputLock then
                system:run(dt)
            end
        end
    end
end

-- Run render systems for the active scene
---@param renderer table
function SceneManager:render(renderer)
    if not self.activeScene then return end

    for _, system in ipairs(self.activeScene.systems.render) do
        if system.run then
            system:run(renderer)
        end
    end
end

-- Handle events for the active scene
---@param event table
function SceneManager:handleEvent(event)
    -- Skip all events if input is locked (during transitions)
    if Transition:isInputLocked() then return end

    if not self.activeScene then return end

    for _, system in ipairs(self.activeScene.systems.event) do
        if system.run then
            system:run(event)
        end
    end
end

local ModuleExports = {
    SceneManager = SceneManager,
    Scene = Scene
}

return ModuleExports
