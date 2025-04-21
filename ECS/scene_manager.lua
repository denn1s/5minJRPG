-- ECS/scene_manager.lua
-- Scene management system for the ECS

local Transition = require("ECS.transition")
local World = require("ECS.world")
local LDtkManager = require("ECS.ldtk.ldtk_manager")
local Scene = require("ECS.scene")
local Camera = require("ECS.camera")

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
---@param cameraX? number Initial camera X position
---@param cameraY? number Initial camera Y position
---@return Scene
function SceneManager:createScene(name, cameraX, cameraY)
    local scene = Scene.new(name)
    scene.camera = Camera.new(scene, self.viewportWidth, self.viewportHeight, cameraX, cameraY)
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

    -- Get the level data for the specified level ID
    local level = ldtk:getLevel(levelId)
    if not level then
        error("Level not found: " .. levelId)
    end

    -- Determine grid size (use LDtk's grid size)
    local gridSize = ldtk:getGridSize()

    -- Get width and height in grid cells
    local gridWidth, gridHeight = ldtk:getLevelGridSize(levelId)

    -- Validate level dimensions
    if gridWidth <= 0 or gridHeight <= 0 then
        error(string.format("Invalid level dimensions: %dx%d", gridWidth, gridHeight))
    end

    -- Create a new world for this level
    print("Creating world of size ", gridWidth, gridHeight, gridSize)
    local world = World.new(gridWidth, gridHeight, gridSize)

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
function SceneManager:transitionToSceneWithFade(sceneName, preserveCurrentScene, duration, out)
    if not self.scenes[sceneName] then
        error("Scene not registered: " .. sceneName)
    end

    -- Start a fade-out transition
    if out then
        Transition:start("fade_out", sceneName, preserveCurrentScene, duration)
    else
        Transition:start("fade_in", sceneName, preserveCurrentScene, duration)
    end

    return self
end

-- Transition to a scene immediately (no fade)
---@param sceneName string
---@param preserveCurrentScene? boolean
---@return SceneManager
function SceneManager:transitionToScene(sceneName, preserveCurrentScene)
    print("transitionToScene", sceneName)
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

-- Transition to a scene by levelId, setting camera and player positions
---@param levelId string
---@param cameraX number
---@param cameraY number
---@param playerX number
---@param playerY number
---@param preserveCurrentScene? boolean
---@param duration? number
---@return SceneManager
function SceneManager:transitionToSceneByLevelId(
    levelId,
    cameraX,
    cameraY,
    playerX,
    playerY,
    preserveCurrentScene,
    duration
)
    print("transitioN to scene by level id", levelId)
    -- Find the scene with the matching levelId
    local targetScene = nil
    for _, scene in pairs(self.scenes) do
        if scene.levelId == levelId then
            targetScene = scene
            break
        end
    end

    if not targetScene then
        error("No scene found with levelId: " .. tostring(levelId))
    end

    -- Set the camera position on the target scene
    targetScene.camera:setPosition(cameraX, cameraY)

    -- Set the player position in the ECS (assuming only one player)
    local playerEntities = self.ecs:getEntitiesWithComponent("player")
    if #playerEntities > 0 then
        local player = playerEntities[1]
        local transform = player:getComponent("transform")
        if transform then
            transform.x = playerX
            transform.y = playerY
        else
            error("Player entity missing transform component")
        end
    else
        error("No player entity found")
    end

    self:transitionToScene(targetScene.name, true)

    -- Perform the fade transition to the scene by name
    return self:transitionToSceneWithFade(targetScene.name, preserveCurrentScene, duration)
end

return SceneManager
