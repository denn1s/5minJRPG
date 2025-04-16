-- example_ldtk_scene.lua
-- Example scene that loads and displays a LDtk map

local Core = require("ECS.core")

local ExampleLDtkScene = {}

-- Create a simple LDtk scene
function ExampleLDtkScene.createLDtkScene(sceneManager, ecs)
    -- Create a scene with a medium-sized world (640x576) to match LDtk dimensions
    local scene = sceneManager:createScene("ldtk_scene", 640, 576)

    -- Add setup systems
    -- First initialize the scene with a fade-in effect
    scene:addSystem("setup", Core.SceneInitSystem.new():init(ecs, true, 0.5))

    -- Create the player entity
    scene:addSystem("setup", require("example_systems").CreatePlayerSystem.new():init(ecs))

    -- Load LDtk map - store the system for later reference
    local ldtkLoadSystem = Core.LDtk.LoadSystem.new():init(ecs, "mini.ldtk", "Level_1")
    scene:addSystem("setup", ldtkLoadSystem)

    -- Load all textures for entities in the scene
    scene:addSystem("setup", Core.TextureLoadSystem.new():init(ecs))

    -- Add update systems
    -- Handle player input
    scene:addSystem("update", require("example_systems").InputSystem.new():init(ecs))

    -- Handle player animations (add before movement system for better synchronization)
    scene:addSystem("update", Core.PlayerAnimationSystem.new():init(ecs))

    -- Update position and handle collisions
    scene:addSystem("update", require("example_systems").MovementSystem.new():init(ecs))

    -- Make the camera follow the player
    scene:addSystem("update", Core.CameraSystem.new():init(ecs, scene.camera, "follow", 0.1))

    -- Add render systems
    -- Add the LDtk tilemap render system - this needs to be added after setup systems have run
    -- so we store the reference and add it in the scene's onActivated callback
    scene.onActivated = function()
        -- Get the LDtk data from the load system
        local ldtkData = ldtkLoadSystem:getParser().data
        local currentLevel = ldtkLoadSystem.currentLevel
        
        -- Create and add the tilemap render system
        local tilemapRenderSystem = Core.LDtk.TilemapRenderSystem.new():init(ecs, ldtkData, currentLevel)
        scene:addSystem("render", tilemapRenderSystem)
        
        print("Added LDtk tilemap render system for level: " .. currentLevel)
    end
    
    -- Use our dedicated SpriteRenderSystem from the systems index - after the tilemap
    scene:addSystem("render", Core.SpriteRenderSystem.new():init(ecs))

    -- Add collider rendering system - after sprite rendering so colliders appear on top
    scene:addSystem("render", Core.ColliderRenderSystem.new():init(ecs))
    
    -- Add debug rendering system
    scene:addSystem("render", Core.DebugSystem.new():init(ecs, sceneManager))

    -- Add event systems
    -- Handle key presses
    scene:addSystem("event", require("example_systems").KeyPressSystem.new():init(ecs))

    -- Set initial camera position to be centered on player's expected position
    -- For Level_1, player starts at (65*8, 14*8) = (520, 112)
    scene.camera:centerOn(520, 112)

    -- Set world properties
    scene.world:setProperty("type", "ldtk_world")

    print("Created LDtk scene")

    return scene
end

return ExampleLDtkScene
