# GameBoy-Style Love2D ECS Game with Scene Management

This is a GameBoy-style game built with Love2D using a custom Entity Component System (ECS) architecture and scene management.

## Project Structure

Here's how the files should be organized:

```
game_directory/
├── main.lua                 # Main entry point
├── .luarc.json              # Lua Language Server configuration
├── example_systems.lua      # Example system implementations
├── example_scenes.lua       # Example scene definitions
├── ECS/                     # ECS framework
│   ├── core.lua             # Core ECS functionality
│   ├── systems.lua          # Base system classes
│   ├── components.lua       # Common component definitions
│   ├── renderer.lua         # Renderer interface
│   └── scene_manager.lua    # Scene management system
```

## How to Run

1. Make sure Love2D is installed:
   ```bash
   sudo pacman -S love
   ```

2. Navigate to the game directory:
   ```bash
   cd game_directory
   ```

3. Run the game:
   ```bash
   love .
   ```

## Controls

- Arrow keys: Move the player
- Z key: Interact with objects/NPCs, confirm selections
- Escape: Quit the game
- Number keys (debug): 
  - 1: Switch to Overworld scene
  - 2: Switch to House scene
  - 3: Switch to Battle scene
  - 0: Return to previous scene

## Understanding the ECS Architecture

### Core Concepts

- **Entities**: Simple objects with a unique ID that serve as containers for components
- **Components**: Pure data containers attached to entities (e.g., Transform, Sprite)
- **Systems**: Logic that operates on entities with specific components

### System Types

1. **Setup Systems**: Run once during initialization
2. **Update Systems**: Run every frame with delta time
3. **Render Systems**: Run every frame with renderer
4. **Event Systems**: Run when specific events occur

## Scene Management

The game uses a scene management system to organize game logic into distinct scenes:

### Scene Concepts

- **Scenes**: Collections of systems that represent different game states (e.g., overworld, house, battle)
- **Scene Transitions**: Moving from one scene to another while preserving necessary state
- **Persistent Entities**: Entities that persist across scene transitions (e.g., the player)

### How Scene Management Works

1. Scenes are registered with the SceneManager
2. Each scene has its own systems for setup, update, render, and events
3. The SceneManager handles transitioning between scenes:
   - Saving the state of the current scene
   - Loading the state of the new scene (or initializing it if first visit)
   - Preserving persistent entities across transitions
4. The main game loop delegates to the SceneManager for update, render, and event handling

### Game Features Demonstrated

1. **Scene Transitions**:
   - Enter a house from the overworld
   - Exit the house back to the overworld
   - Enter a battle from the overworld
   - Return to the overworld after a battle

2. **State Preservation**:
   - Player attributes (position, health, experience) persist across scenes
   - Scene-specific entities are restored when returning to a scene

3. **Scene-Specific Logic**:
   - Overworld: Exploration and battle triggers
   - House: Interactive objects
   - Battle: Turn-based combat with UI

## Extending the Game

### Adding New Scenes

Create new scene setup functions in `example_scenes.lua`:

```lua
function ExampleScenes.createNewScene(sceneManager, ecs)
    local scene = sceneManager:createScene("newScene")
    
    -- Add scene-specific systems
    scene:addSystem("setup", YourSetupSystem.new():init(ecs))
    scene:addSystem("update", YourUpdateSystem.new():init(ecs))
    scene:addSystem("render", YourRenderSystem.new():init(ecs))
    
    return scene
end
```

Then register and transition to it:

```lua
-- In love.load()
ExampleScenes.createNewScene(SceneManager, ECS)

-- To transition to the scene
SceneManager:transitionToScene("newScene", true)
```

### Adding New Components

Create new component constructors in `ECS/components.lua`:

```lua
function Components.newComponent(param1, param2)
    return {
        name = "newComponent",
        property1 = param1,
        property2 = param2
    }
end
```

### Adding New Systems

Create new system classes in a file similar to `example_systems.lua`:

1. Inherit from an appropriate base system
2. Implement the `run` method with the required parameters
3. Add the system to the appropriate scene

### Creating Persistent Game State

Mark entities to persist across scene transitions:

```lua
SceneManager:markEntityAsPersistent(entity)
```

This is useful for:
- The player character
- Global game state (quest progress, inventory)
- Shared UI elements

## Scene Management Advanced Features

### Scene Stack

The SceneManager maintains references to both the active scene and the previous scene, allowing for a simple scene stack. This enables:
- Nested scene transitions (e.g., overworld → house → battle)
- Returning to previous scenes in the correct order
- Preserving state through multiple scene transitions

### Scene Initialization Control

Scenes are only initialized once when first visited, but you can control this behavior:

```lua
-- Force a scene to reinitialize
SceneManager.sceneStates["sceneName"].initialized = false
```

### Scene-Specific Entity Management

Entities belong to specific scenes unless marked as persistent. This separation allows:
- Memory efficiency (only relevant entities are active)
- Logical separation of game elements
- Independent scene development

## Troubleshooting

- **Undefined global 'love'**: Make sure your `.luarc.json` is in the project root
- **Missing ECS modules**: Check your file structure and require paths
- **Blank screen**: Verify that your entity positions are within screen bounds
- **Error in Love2D**: Check the console for detailed error messages
- **Scene transition issues**: Verify that scene names match between registration and transition calls
- **Entities disappearing after scene transition**: Check if they should be marked as persistent
