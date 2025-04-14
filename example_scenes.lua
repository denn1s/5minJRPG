-- example_scenes.lua
-- Example scene definitions with fade transitions

local ExampleSystems = require("example_systems")
local Components = require("ECS.components")
local SceneInitSystem = require("ECS.systems.scene_init_system")

local ExampleScenes = {}

-- Default transition duration
local DEFAULT_TRANSITION_DURATION = 0.75

-- Create an overworld scene
function ExampleScenes.createOverworldScene(sceneManager, ecs)
    local scene = sceneManager:createScene("overworld")

    -- Add systems
    -- Setup systems
    scene:addSystem("setup", SceneInitSystem.new():init(ecs, true, DEFAULT_TRANSITION_DURATION))
    scene:addSystem("setup", ExampleSystems.CreatePlayerSystem.new():init(ecs))
    scene:addSystem("setup", ExampleSystems.CreateOverworldSystem.new():init(ecs))

    -- Update systems
    scene:addSystem("update", ExampleSystems.InputSystem.new():init(ecs))
    scene:addSystem("update", ExampleSystems.MovementSystem.new():init(ecs))
    scene:addSystem("update", ExampleSystems.OverworldInteractionSystem.new():init(ecs))

    -- Render systems
    scene:addSystem("render", ExampleSystems.SpriteRenderSystem.new():init(ecs))

    -- Event systems
    scene:addSystem("event", ExampleSystems.KeyPressSystem.new():init(ecs))

    return scene
end

-- Create a house scene
function ExampleScenes.createHouseScene(sceneManager, ecs)
    local scene = sceneManager:createScene("house")

    -- Add systems
    -- Setup systems
    scene:addSystem("setup", SceneInitSystem.new():init(ecs, true, DEFAULT_TRANSITION_DURATION))
    scene:addSystem("setup", ExampleSystems.CreateHouseSystem.new():init(ecs))

    -- Update systems
    scene:addSystem("update", ExampleSystems.InputSystem.new():init(ecs))
    scene:addSystem("update", ExampleSystems.MovementSystem.new():init(ecs))
    scene:addSystem("update", ExampleSystems.HouseInteractionSystem.new():init(ecs))

    -- Render systems
    scene:addSystem("render", ExampleSystems.SpriteRenderSystem.new():init(ecs))

    -- Event systems
    scene:addSystem("event", ExampleSystems.KeyPressSystem.new():init(ecs))

    return scene
end

-- Create a battle scene
function ExampleScenes.createBattleScene(sceneManager, ecs)
    local scene = sceneManager:createScene("battle")

    -- Add systems
    -- Setup systems
    scene:addSystem("setup", SceneInitSystem.new():init(ecs, true, DEFAULT_TRANSITION_DURATION))
    scene:addSystem("setup", ExampleSystems.CreateBattleSystem.new():init(ecs))

    -- Update systems
    scene:addSystem("update", ExampleSystems.BattleInputSystem.new():init(ecs))
    scene:addSystem("update", ExampleSystems.BattleLogicSystem.new():init(ecs))

    -- Render systems
    scene:addSystem("render", ExampleSystems.BattleRenderSystem.new():init(ecs))

    -- Event systems
    scene:addSystem("event", ExampleSystems.KeyPressSystem.new():init(ecs))

    return scene
end

return ExampleScenes
