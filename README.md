# GameBoy-Style Love2D ECS Game Engine

A lightweight, GameBoy-inspired game engine built with Love2D using a custom Entity Component System (ECS) architecture with scene management, camera system, and world management.

## Project Structure

```
game_directory/
├── main.lua                 # Main entry point
├── .luarc.json              # Lua Language Server configuration
├── ECS/                     # ECS framework
│   ├── core.lua             # Core ECS functionality
│   ├── systems.lua          # Base system classes
│   ├── components.lua       # Common component definitions
│   ├── renderer.lua         # Renderer interface 
│   ├── scene_manager.lua    # Scene management system
│   ├── transition.lua       # Scene transition effects
│   ├── camera.lua           # Camera system
│   ├── world.lua            # World management
│   └── systems/             # Common systems
│       ├── camera_system.lua      # Camera movement system
│       ├── transition_system.lua  # Transition effect system
│       └── scene_init_system.lua  # Scene initialization system
├── example_systems.lua      # Example system implementations
└── example_scenes.lua       # Example scene definitions
```

## Getting Started

### Prerequisites

- [Love2D](https://love2d.org/) (version 11.3 or higher recommended)
- For development: [Lua Language Server](https://github.com/LuaLS/lua-language-server) for code completion

### Running the Game

```bash
# On Arch Linux
sudo pacman -S love

# Navigate to game directory
cd game_directory

# Run the game
love .
```

### Default Controls

- Arrow keys: Move player
- Z: Interact/Confirm
- WASD: Debug camera movement (if enabled)
- C: Center camera on player (if enabled)
- 1-3: Debug scene switching
- 0: Return to previous scene
- ESC: Quit

## Architecture Overview

### Entity Component System (ECS)

The engine uses an Entity Component System architecture with these core concepts:

1. **Entities**: Simple containers with a unique ID
2. **Components**: Pure data containers attached to entities
3. **Systems**: Logic that operates on entities with specific components

### Scene Management

Scenes represent different game states (e.g., overworld, battle) and contain:

1. Their own collection of systems
2. A camera instance for viewport management
3. A world instance for spatial boundaries
4. Persistent/non-persistent entities

### Camera System

The camera defines the viewport into the game world:

1. Transforms world coordinates to screen coordinates for rendering
2. Can follow entities or remain fixed
3. Manages different behaviors per scene

### World System

The world defines the boundaries and properties of each scene:

1. Stores world dimensions (which may be larger than the viewport)
2. Contains scene-specific properties
3. Provides boundary checking

## Creating a Game with the Engine

### 1. Setting up the Entry Point

```lua
-- main.lua
local ECS = require("ECS.core")
local Renderer = require("ECS.renderer")
local SceneManager = require("ECS.scene_manager").SceneManager
local MyScenes = require("my_scenes")

-- Game constants
local SCREEN_WIDTH = 160
local SCREEN_HEIGHT = 144
local SCALE = 4

function love.load()
    -- Set up window
    love.window.setTitle("My Game")
    love.window.setMode(SCREEN_WIDTH * SCALE, SCREEN_HEIGHT * SCALE, {
        vsync = true,
        resizable = false
    })
    
    -- Create renderer
    renderer = Renderer.new(SCREEN_WIDTH, SCREEN_HEIGHT, SCALE)
    
    -- Initialize scene manager with viewport dimensions
    SceneManager:init(ECS, SCREEN_WIDTH, SCREEN_HEIGHT)
    
    -- Create scenes
    MyScenes.createMainMenuScene(SceneManager, ECS)
    MyScenes.createGameplayScene(SceneManager, ECS)
    
    -- Start with initial scene
    SceneManager:transitionToScene("main_menu")
end

function love.update(dt)
    SceneManager:update(dt)
end

function love.draw()
    renderer:begin()
    
    -- Set the camera from the active scene
    if SceneManager.activeScene then
        renderer:setCamera(SceneManager.activeScene.camera)
    end
    
    SceneManager:render(renderer)
    renderer:end_drawing()
    renderer:draw_to_screen()
end

function love.keypressed(key, scancode, isrepeat)
    local event = {type = "keypressed", key = key, scancode = scancode, isrepeat = isrepeat}
    SceneManager:handleEvent(event)
    
    if key == "escape" then
        love.event.quit()
    end
end
```

### 2. Creating Components

Components are pure data containers. Define new components in a separate file or extend `ECS/components.lua`:

```lua
-- my_components.lua
local Components = require("ECS.components")

-- Add a health component
function Components.health(current, max)
    return {
        name = "health",
        current = current or 100,
        max = max or 100
    }
end

-- Add an inventory component
function Components.inventory(capacity)
    return {
        name = "inventory",
        items = {},
        capacity = capacity or 10
    }
end

return Components
```

### 3. Creating Systems

Systems implement game logic. Derive from the base system classes:

```lua
-- my_systems.lua
local Systems = require("ECS.systems")
local Components = require("my_components")

local MySystems = {}

-- Health regeneration system
MySystems.HealthRegenSystem = setmetatable({}, {__index = Systems.UpdateSystem})
MySystems.HealthRegenSystem.__index = MySystems.HealthRegenSystem

function MySystems.HealthRegenSystem.new()
    local system = Systems.UpdateSystem.new()
    setmetatable(system, MySystems.HealthRegenSystem)
    return system
end

function MySystems.HealthRegenSystem:init(ecs, regenRate)
    Systems.UpdateSystem.init(self, ecs)
    self.regenRate = regenRate or 1
    return self
end

function MySystems.HealthRegenSystem:run(dt)
    local entities = self.ecs:getEntitiesWithComponent("health")
    
    for _, entity in ipairs(entities) do
        local health = entity:getComponent("health")
        if health.current < health.max then
            health.current = math.min(health.max, health.current + self.regenRate * dt)
        end
    end
end

return MySystems
```

### 4. Creating Scenes

Scenes organize your game states and systems:

```lua
-- my_scenes.lua
local MySystems = require("my_systems")
local Components = require("my_components")
local CameraSystem = require("ECS.systems.camera_system")
local SceneInitSystem = require("ECS.systems.scene_init_system")

local MyScenes = {}

function MyScenes.createGameplayScene(sceneManager, ecs)
    -- Create a scene with a larger world (320x288)
    local scene = sceneManager:createScene("gameplay", 320, 288)
    
    -- Add setup systems
    scene:addSystem("setup", SceneInitSystem.new():init(ecs, true))
    scene:addSystem("setup", MySystems.CreatePlayerSystem.new():init(ecs))
    scene:addSystem("setup", MySystems.CreateEnemiesSystem.new():init(ecs))
    
    -- Add update systems
    scene:addSystem("update", MySystems.InputSystem.new():init(ecs))
    scene:addSystem("update", MySystems.MovementSystem.new():init(ecs))
    scene:addSystem("update", MySystems.CollisionSystem.new():init(ecs))
    scene:addSystem("update", MySystems.HealthRegenSystem.new():init(ecs, 2))
    
    -- Add camera system - follow player with smooth movement
    scene:addSystem("update", CameraSystem.new():init(ecs, scene.camera, "follow", 0.1))
    
    -- Add render systems
    scene:addSystem("render", MySystems.SpriteRenderSystem.new():init(ecs))
    scene:addSystem("render", MySystems.UIRenderSystem.new():init(ecs))
    
    -- Add event systems
    scene:addSystem("event", MySystems.KeyPressSystem.new():init(ecs))
    
    -- Set world properties
    scene.world:setProperty("type", "forest")
    scene.world:setProperty("difficulty", 2)
    
    return scene
end

return MyScenes
```

### 5. Working with Entities

Create and manage entities in your systems:

```lua
-- In a setup system:
function CreatePlayerSystem:run()
    local player = self.ecs:createEntity()
        :addComponent(Components.transform(80, 72))
        :addComponent(Components.sprite(playerSprite, 8, 8))
        :addComponent(Components.velocity(0, 0))
        :addComponent(Components.input())
        :addComponent(Components.health(100, 100))
    
    -- Make player persistent across scenes
    local SceneManager = require("ECS.scene_manager").SceneManager
    SceneManager:markEntityAsPersistent(player)
end
```

### 6. Using the Camera System

The camera transforms world coordinates to screen coordinates for rendering:

#### Setting Up Different Camera Behaviors

```lua
-- Fixed camera (e.g., for UI scenes)
scene:addSystem("update", CameraSystem.new():init(ecs, scene.camera, "fixed"))

-- Following camera (e.g., for overworld)
scene:addSystem("update", CameraSystem.new():init(ecs, scene.camera, "follow", 0.1))
```

#### Manual Camera Control

```lua
-- In an update system:
function MyCameraControlSystem:run(dt)
    local camera = SceneManager.activeScene.camera
    local player = self.ecs:getEntitiesWithComponent("player")[1]
    
    if player then
        local transform = player:getComponent("transform")
        camera:centerOn(transform.x, transform.y)
    end
end
```

#### Using Camera Transformations in Rendering

The renderer automatically transforms world coordinates to screen coordinates. However, you can also do this manually:

```lua
function MyCustomRenderSystem:run(renderer)
    local camera = SceneManager.activeScene.camera
    local worldX, worldY = 100, 100
    local screenX, screenY = camera:worldToScreen(worldX, worldY)
    
    -- Draw at screen coordinates
    renderer:draw_rectangle(worldX, worldY, 10, 10, 1, true)
    -- Behind the scenes, the renderer calls camera:worldToScreen()
end
```

### 7. Working with the World

The world defines boundaries and properties for each scene:

```lua
-- Setting world properties
scene.world:setProperty("weather", "rain")
scene.world:setProperty("enemyDensity", 0.8)

-- Getting world properties
function WeatherSystem:run(dt)
    local world = SceneManager.activeScene.world
    local weather = world:getProperty("weather")
    
    if weather == "rain" then
        -- Render rain particles
    end
end

-- Checking world bounds
function MovementSystem:run(dt)
    for _, entity in ipairs(entities) do
        local transform = entity:getComponent("transform")
        transform.x = transform.x + velocity.dx * dt
        
        -- Keep within world bounds
        local world = SceneManager.activeScene.world
        if transform.x < 0 then
            transform.x = 0
        elseif transform.x > world.width then
            transform.x = world.width
        end
    end
end
```

### 8. Scene Transitions

Transition between scenes with optional fade effects:

```lua
-- Simple transition
SceneManager:transitionToScene("level_1")

-- Transition with fade effect
SceneManager:transitionToSceneWithFade("battle", true, 0.5)

-- Return to previous scene
SceneManager:returnToPreviousScene()
```

### 9. Creating a Portal/Door Between Scenes

```lua
-- In a setup system:
function CreateDoorSystem:run()
    self.ecs:createEntity()
        :addComponent(Components.transform(120, 80))
        :addComponent(Components.sprite(doorSprite, 16, 24))
        :addComponent(Components.collision(8))
        :addComponent({
            name = "portal",
            targetScene = "house_interior",
            enterX = 80,  -- Where to place player in target scene
            enterY = 120
        })
end

-- In an interaction system:
function DoorInteractionSystem:run(dt)
    local player = self.ecs:getEntitiesWithComponent("player")[1]
    if not player then return end
    
    local playerPos = player:getComponent("transform")
    local doors = self.ecs:getEntitiesWithComponent("portal")
    
    for _, door in ipairs(doors) do
        local doorPos = door:getComponent("transform")
        local portal = door:getComponent("portal")
        local distance = calculateDistance(playerPos, doorPos)
        
        if distance < 10 and love.keyboard.isDown("z") then
            -- Update player position for the new scene
            playerPos.x = portal.enterX
            playerPos.y = portal.enterY
            
            -- Transition to the new scene
            SceneManager:transitionToSceneWithFade(portal.targetScene, true, 0.5)
        end
    end
end
```

## Troubleshooting

### Common Issues

1. **Entities not appearing on screen**:
   - Check if they're within camera view
   - Verify their transforms have valid coordinates
   - Ensure world coordinates are properly transformed to screen coordinates

2. **Entities disappearing after scene transitions**:
   - Make sure they're properly marked as persistent if needed:
     ```lua
     SceneManager:markEntityAsPersistent(entity)
     ```

3. **Camera not following player**:
   - Verify the camera system is configured correctly
   - Check that the player entity has a "player" component

4. **Rendering issues**:
   - Remember that all rendering functions expect world coordinates
   - The renderer transforms them to screen coordinates automatically

5. **Collisions not working**:
   - Check collision radius values
   - Verify entities have both transform and collision components

## Extending the Engine

### Adding New Component Types

1. Create a new component constructor function in `components.lua` or your custom file
2. Follow the component pattern - provide a `name` field and any data needed

### Creating Custom Systems

1. Inherit from the base system types in `ECS/systems.lua`
2. Implement the `run` method with appropriate parameters
3. Add your system to the appropriate scene

### Extending Camera Functionality

To add new camera behaviors:

1. Create a new camera system inheriting from `UpdateSystem`
2. Implement custom camera movement in the `run` method
3. Access the scene's camera via `SceneManager.activeScene.camera`

### Creating Custom Renderers

To create special rendering effects:

1. Create a new renderer system inheriting from `RenderSystem`
2. Use the provided renderer's drawing functions
3. Access camera transformations via the renderer's transform methods

## Performance Tips

1. **Optimize Entity Queries**:
   - Cache results of `getEntitiesWithComponent()` when possible
   - Use more specific component combinations to reduce result set

2. **Efficient Rendering**:
   - Only render entities within the camera's view
   - Use occlusion culling for large worlds
   - Batch similar rendering operations

3. **Scene Management**:
   - Keep entity count reasonable per scene
   - Only mark entities as persistent when necessary
   - Clean up unused entities when transitioning scenes

## Examples

Check the example systems and scenes for working implementations of:

- Player movement
- Camera following
- Scene transitions
- Entity interactions
- World boundaries

## License

GPL3
