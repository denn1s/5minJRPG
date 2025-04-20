-- example_ldtk_scene.lua
-- Example scene using LDtk map system

local Core = require("ECS.core")
local LDtk = require("ECS.ldtk")
local dump = require("libs.dump")

local ExampleLDtkScene = {}

-- Create an LDtk scene
function ExampleLDtkScene.createLDtkScene(sceneManager, ecs)
  -- Create a scene
  local scene = sceneManager:createScene("ldtk_scene", 500, 12)

  -- Initialize world from LDtk level
  sceneManager:initWorldFromLDtk(scene, "Level_1")
  -- Add setup systems in the correct order:

  -- Initialize the scene with a fade-in effect
  scene:addSystem("setup", Core.SceneInitSystem.new():init(ecs, true, 0.5))

  -- Create the player entity (same as in example scenes)
  scene:addSystem("setup", require("example_systems").CreatePlayerSystem.new():init(ecs))

  -- Load all textures for entities in the scene
  scene:addSystem("setup", Core.TextureLoadSystem.new():init(ecs))
  scene:addSystem("setup", LDtk.TilesetPreloadSystem.new():init(ecs))

  -- Add update systems
  -- Handle player input
  scene:addSystem("update", require("example_systems").InputSystem.new():init(ecs))

  scene:addSystem("update", Core.ColliderSystem.new():init(ecs, scene.levelId))

  -- Handle player animations
  scene:addSystem("update", Core.PlayerAnimationSystem.new():init(ecs))

  -- Update position and handle collisions
  scene:addSystem("update", require("ECS.core.movement_system").new():init(ecs))

  -- Make the camera follow the player
  scene:addSystem("update", Core.CameraSystem.new():init(ecs, scene.camera))

  -- Sync the grid position of entities with their pixel position
  scene:addSystem("update", Core.GridSyncSystem.new():init(ecs, scene.camera))

  -- Add render systems
  -- Add the LDtk tilemap render system (renders the current level)
  scene:addSystem("render", LDtk.TilemapRenderSystem.new():init(ecs, scene.levelId))

  -- Use our dedicated SpriteRenderSystem from the systems index
  scene:addSystem("render", Core.SpriteRenderSystem.new():init(ecs))

  -- Add collider rendering system for debugging
  scene:addSystem("render", Core.ColliderRenderSystem.new():init(ecs))

  scene:addSystem("render", require("example_systems").IntGridRenderSystem.new():init(ecs, scene.levelId))


  --     -- Add event systems
  --     -- Handle key presses
  --     scene:addSystem("event", require("example_systems").KeyPressSystem.new():init(ecs))
  --     print("Created LDtk scene")

  return scene
end

return ExampleLDtkScene
