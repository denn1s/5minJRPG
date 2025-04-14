-- example_scenes.lua
-- Example scene definitions with fade transitions and camera/world support
--
local TextureManager = require("ECS.texture_manager")
local ExampleSystems = require("example_systems")
local SceneInitSystem = require("ECS.systems.scene_init_system")
local CameraSystem = require("ECS.systems.camera_system")
local TextureLoadSystem = require("ECS.systems.texture_load_system")
local SpriteRenderSystem = require("ECS.systems.sprite_render_system")

local ExampleScenes = {}

-- Default transition duration
local DEFAULT_TRANSITION_DURATION = 0.75

function ExampleScenes.createOverworldScene(sceneManager, ecs)
    -- Create a scene with a bigger world (320x288 - 2x screen size)
    local scene = sceneManager:createScene("overworld", 320, 288)
    
    -- Initialize the texture manager globally
    -- This happens once in your application, not per scene
    TextureManager.init(nil, true) -- nil for default color map, true for debug mode
    
    -- Add systems in the correct order
    -- Setup systems
    scene:addSystem("setup", SceneInitSystem.new():init(ecs, true, DEFAULT_TRANSITION_DURATION))
    
    -- First: Create entities with texture components
    scene:addSystem("setup", ExampleSystems.PlayerSetupSystem.new():init(ecs))
    scene:addSystem("setup", ExampleSystems.CreateOverworldSystem.new():init(ecs))
    
    -- Second: Load all textures referenced by any entity
    scene:addSystem("setup", TextureLoadSystem.new():init(ecs))

    -- Update systems
    scene:addSystem("update", ExampleSystems.InputSystem.new():init(ecs))
    scene:addSystem("update", ExampleSystems.MovementSystem.new():init(ecs))
    scene:addSystem("update", ExampleSystems.OverworldInteractionSystem.new():init(ecs))
    scene:addSystem("update", CameraSystem.new():init(ecs, scene.camera, "follow"))

    -- Render systems - the sprite render system now uses the global texture manager
    scene:addSystem("render", SpriteRenderSystem.new():init(ecs))

    -- Event systems
    scene:addSystem("event", ExampleSystems.KeyPressSystem.new():init(ecs))

    -- Set initial camera position (center of the world)
    scene.camera:setPosition(80, 72)
    
    -- Set world properties
    scene.world:setProperty("type", "overworld")
    scene.world:setProperty("encounterRate", 0.1)

    return scene
end

-- Create a house scene
function ExampleScenes.createHouseScene(sceneManager, ecs)
    -- House scene is exactly one screen in size
    local scene = sceneManager:createScene("house")

    -- Add systems
    -- Setup systems
    scene:addSystem("setup", SceneInitSystem.new():init(ecs, true, DEFAULT_TRANSITION_DURATION))
    scene:addSystem("setup", ExampleSystems.CreateHouseSystem.new():init(ecs))

    -- Update systems
    scene:addSystem("update", ExampleSystems.InputSystem.new():init(ecs))
    scene:addSystem("update", ExampleSystems.MovementSystem.new():init(ecs))
    scene:addSystem("update", ExampleSystems.HouseInteractionSystem.new():init(ecs))
    -- Add camera system (fixed in the house - world is same size as viewport)
    scene:addSystem("update", CameraSystem.new():init(ecs, scene.camera, "fixed"))

    -- Render systems
    scene:addSystem("render", ExampleSystems.SpriteRenderSystem.new():init(ecs))

    -- Event systems
    scene:addSystem("event", ExampleSystems.KeyPressSystem.new():init(ecs))

    -- Set initial camera position (top-left)
    scene.camera:setPosition(0, 0)

    -- Set world properties
    scene.world:setProperty("type", "house")
    scene.world:setProperty("interior", true)

    return scene
end

-- Create a battle scene
function ExampleScenes.createBattleScene(sceneManager, ecs)
    -- Battle scene is exactly one screen in size
    local scene = sceneManager:createScene("battle")

    -- Add systems
    -- Setup systems
    scene:addSystem("setup", SceneInitSystem.new():init(ecs, true, DEFAULT_TRANSITION_DURATION))
    scene:addSystem("setup", ExampleSystems.CreateBattleSystem.new():init(ecs))

    -- Update systems
    scene:addSystem("update", ExampleSystems.BattleInputSystem.new():init(ecs))
    scene:addSystem("update", ExampleSystems.BattleLogicSystem.new():init(ecs))
    -- Add camera system (fixed for battle - no scrolling)
    scene:addSystem("update", CameraSystem.new():init(ecs, scene.camera, "fixed"))

    -- Render systems
    scene:addSystem("render", ExampleSystems.BattleRenderSystem.new():init(ecs))

    -- Event systems
    scene:addSystem("event", ExampleSystems.KeyPressSystem.new():init(ecs))

    -- Set initial camera position (top-left)
    scene.camera:setPosition(0, 0)

    -- Set world properties
    scene.world:setProperty("type", "battle")
    scene.world:setProperty("background", "grass")

    return scene
end

return ExampleScenes
