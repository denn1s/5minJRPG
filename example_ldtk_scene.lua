-- example_ldtk_scene.lua
-- Example scene using LDtk map system

local Core = require("ECS.core")
local LDtk = require("ECS.ldtk")
local TextureManager = require("ECS.texture_manager")

local ExampleLDtkScene = {}

-- Create an LDtk scene
function ExampleLDtkScene.createLDtkScene(sceneManager, ecs)
    -- Create a scene
    local scene = sceneManager:createScene("ldtk_scene", 320, 288)

    local map = "assets/map.ldtk"
    local level = "Level_1" -- the level for this scene in the map
    
    -- Create LDtk parser for our map file
    local ldtkParser = LDtk.Parser.new(map)
    
    -- Make sure the parser has loaded the data
    if not ldtkParser:load() then   -- the map is only loaded once across scenes
        print("Failed to load LDtk data")
        return scene
    end
    
    -- Add setup systems in the correct order:
    
    -- 1. First, add the tileset preload system to ensure all tilesets are loaded
    scene:addSystem("setup", LDtk.TilesetPreloadSystem.new():init(ecs))
    
    -- 2. Initialize the scene with a fade-in effect
    scene:addSystem("setup", Core.SceneInitSystem.new():init(ecs, true, 0.5))
    
    -- 3. Add other setup systems
    scene:addSystem("setup", LDtk.TilemapSetupSystem.new():init(ecs, ldtkParser))
    
    -- Add the LDtk loader system (manages level loading)
    local ldtkSystem = LDtk.LoadSystem.new():init(ecs, map, "Level_1")  --uses the pre loaded map
    scene:addSystem("setup", ldtkSystem)
    
    -- Create the player entity (same as in example scenes)
    scene:addSystem("setup", require("example_systems").CreatePlayerSystem.new():init(ecs))
    
    -- Load all textures for entities in the scene
    scene:addSystem("setup", Core.TextureLoadSystem.new():init(ecs))
    
    -- Add update systems
    -- Handle player input
    scene:addSystem("update", require("example_systems").InputSystem.new():init(ecs))
    
    -- Handle player animations
    scene:addSystem("update", Core.PlayerAnimationSystem.new():init(ecs))
    
    -- Update position and handle collisions
    scene:addSystem("update", require("example_systems").MovementSystem.new():init(ecs))
    
    -- Make the camera follow the player
    scene:addSystem("update", Core.CameraSystem.new():init(ecs, scene.camera, "follow"))
    
    -- Add the door system for LDtk door handling
    scene:addSystem("update", LDtk.DoorSystem.new():init(ecs, ldtkSystem))
    
    -- Add render systems
    -- Add the LDtk tilemap render system (renders the current level)
    scene:addSystem("render", LDtk.TilemapRenderSystem.new():init(ecs, ldtkParser.data, "Level_0"))
    
    -- Use our dedicated SpriteRenderSystem from the systems index
    scene:addSystem("render", Core.SpriteRenderSystem.new():init(ecs))
    
    -- Add collider rendering system for debugging
    scene:addSystem("render", Core.ColliderRenderSystem.new():init(ecs))
    
    -- Add debug system
    scene:addSystem("render", Core.DebugSystem.new():init(ecs, sceneManager))
    
    -- Add event systems
    -- Handle key presses
    scene:addSystem("event", require("example_systems").KeyPressSystem.new():init(ecs))
    
    -- Set initial camera position (center of the world)
    scene.camera:setPosition(80, 72)
    
    -- Add F12 key binding to toggle TextureManager stats
    scene.keyBindings = {
        ["f12"] = function()
            print("\n=== TextureManager Statistics ===")
            TextureManager.printCacheStats()
            TextureManager.printTilesetCacheStats()
            print("===============================\n")
        end
    }
    
    print("Created LDtk scene")
    
    return scene
end

return ExampleLDtkScene
