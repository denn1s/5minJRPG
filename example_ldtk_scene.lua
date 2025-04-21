-- example_ldtk_scene.lua
local LDtkScene = require("create_ldtk_scene")
local ExampleSystems = require("example_systems")
local DoorTransitionSystem = require("door_transition_system")

local ExampleLDtkScene = {}

-- Helper to add example systems to a scene
local function addExampleSystems(scene, ecs, sceneManager, levelId)
    -- Create player entity
    -- scene:addSystem("setup", ExampleSystems.CreatePlayerSystem.new():init(ecs))

    -- Input system for player control
    scene:addSystem("update", ExampleSystems.InputSystem.new():init(ecs))

    -- Transition to doors
    scene:addSystem("update", DoorTransitionSystem.new(sceneManager):init(ecs, levelId))

    -- Level transition input system (handle keys 1,2,3)
    scene:addSystem("update", ExampleSystems.LevelTransitionInputSystem.new():init(ecs, sceneManager))

    -- scene:addSystem("render", ExampleSystems.IntGridRenderSystem.new():init(ecs, levelId))
    -- scene:addSystem("render", ExampleSystems.DoorRenderSystem.new():init(ecs, levelId))
end

-- Create Level_0 scene
function ExampleLDtkScene.createLevel0(sceneManager, ecs)
    local ldtkScene = LDtkScene.new(sceneManager, ecs, "Level_0_Scene", 0, 0, "Level_0")
    addExampleSystems(ldtkScene.scene, ecs, sceneManager, "Level_0")
    return ldtkScene.scene
end

-- Create Level_1 scene
function ExampleLDtkScene.createLevel1(sceneManager, ecs)
    local ldtkScene = LDtkScene.new(sceneManager, ecs, "Level_1_Scene", 0, 0, "Level_1")
    addExampleSystems(ldtkScene.scene, ecs, sceneManager, "Level_1")
    return ldtkScene.scene
end

-- Create Level_2 scene
function ExampleLDtkScene.createLevel2(sceneManager, ecs)
    local ldtkScene = LDtkScene.new(sceneManager, ecs, "Level_2_Scene", 0, 0, "Level_2")
    addExampleSystems(ldtkScene.scene, ecs, sceneManager, "Level_2")
    return ldtkScene.scene
end

return ExampleLDtkScene

