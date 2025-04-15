-- example_scenes.lua
-- Simple scene definitions for a basic game example

local ExampleSystems = require("example_systems")
local Core = require("ECS.core")

local ExampleScenes = {}

-- Default transition duration
local DEFAULT_TRANSITION_DURATION = 0.5

-- Create a simple overworld scene
function ExampleScenes.createOverworldScene(sceneManager, ecs)
    -- Create a scene with a medium-sized world (320x288)
    local scene = sceneManager:createScene("overworld", 320, 288)

    -- Add setup systems
    -- First initialize the scene with a fade-in effect
    scene:addSystem("setup", Core.SceneInitSystem.new():init(ecs, true, DEFAULT_TRANSITION_DURATION))
    
    -- Create the player entity
    scene:addSystem("setup", ExampleSystems.CreatePlayerSystem.new():init(ecs))
    
    -- Create world objects (trees, rocks, etc.)
    scene:addSystem("setup", ExampleSystems.CreateWorldSystem.new():init(ecs))
    
    -- Load all textures for entities in the scene
    scene:addSystem("setup", Core.TextureLoadSystem.new():init(ecs))

    -- Add update systems
    -- Handle player input
    scene:addSystem("update", ExampleSystems.InputSystem.new():init(ecs))
    
    -- Handle player animations (add before movement system for better synchronization)
    scene:addSystem("update", Core.PlayerAnimationSystem.new():init(ecs))
    
    -- Update position and handle collisions
    scene:addSystem("update", ExampleSystems.MovementSystem.new():init(ecs))
    
    -- Make the camera follow the player
    scene:addSystem("update", Core.CameraSystem.new():init(ecs, scene.camera, "follow"))

    -- Add render systems
    -- Use our dedicated SpriteRenderSystem from the systems index
    scene:addSystem("render", Core.SpriteRenderSystem.new():init(ecs))

    -- Add event systems
    -- Handle key presses
    scene:addSystem("event", ExampleSystems.KeyPressSystem.new():init(ecs))

    -- Set initial camera position (center of the world)
    scene.camera:setPosition(80, 72)
    
    -- Set world properties
    scene.world:setProperty("type", "overworld")
    
    print("Created overworld scene")
    
    return scene
end

return ExampleScenes
