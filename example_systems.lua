-- example_systems.lua
-- Example systems for a simple game with sprites

local Systems = require("ECS.systems")
local Components = require("ECS.components")

local ExampleSystems = {}

-- Setup System: Create Player
ExampleSystems.CreatePlayerSystem = setmetatable({}, {__index = Systems.SetupSystem})
ExampleSystems.CreatePlayerSystem.__index = ExampleSystems.CreatePlayerSystem

function ExampleSystems.CreatePlayerSystem.new()
    local system = Systems.SetupSystem.new()
    setmetatable(system, ExampleSystems.CreatePlayerSystem)
    return system
end

function ExampleSystems.CreatePlayerSystem:init(ecs)
    Systems.SetupSystem.init(self, ecs)
    return self
end


function ExampleSystems.CreatePlayerSystem:run()
    -- Path to the player spritesheet
    local heroSpritesheetPath = "assets/spritesheets/hero.png"

    -- Create player entity
    local player = self.ecs:createEntity()

    -- Add a texture component for loading the spritesheet
    player:addComponent(Components.texture(heroSpritesheetPath))

    -- Add a sprite component for rendering
    player:addComponent(Components.sprite(heroSpritesheetPath, 16, 16, 0, 0))

    -- Add transform component for position
    player:addComponent(Components.transform(65, 4))

    -- Add velocity component for movement
    player:addComponent(Components.velocity(0, 0))

    -- Add input component for player control
    player:addComponent(Components.input())

    -- Add a smaller collider component with offset
    -- Width: 16px (same as sprite width)
    -- Height: if you want 8px at the bottom of the 16px sprite, it's 8px high with an 8px Y offset
    player:addComponent(Components.collider(16, 8, 0, 8, true))  -- true enables debug rendering

    -- Add player-specific component with stats
    player:addComponent({
        name = "player",
        health = 100,
        maxHealth = 100,
        experience = 0,
        level = 1
    })

    -- Mark player as persistent across scenes
    local SceneManager = require("ECS.scene_manager")
    SceneManager:markEntityAsPersistent(player)

    return player
end

-- Update System: Process Input
ExampleSystems.InputSystem = setmetatable({}, {__index = Systems.UpdateSystem})
ExampleSystems.InputSystem.__index = ExampleSystems.InputSystem

function ExampleSystems.InputSystem.new()
    local system = Systems.UpdateSystem.new()
    setmetatable(system, ExampleSystems.InputSystem)
    return system
end

function ExampleSystems.InputSystem:init(ecs)
    Systems.UpdateSystem.init(self, ecs)
    return self
end

function ExampleSystems.InputSystem:run(dt)
    -- Get entities with input component
    local entities = self.ecs:getEntitiesWithComponent("input")

    for _, entity in ipairs(entities) do
        local velocity = entity:getComponent("velocity")
        local input = entity:getComponent("input")

        if velocity and input then
            -- Reset velocity
            velocity.dx = 0
            velocity.dy = 0

            -- Apply movement based on key presses
            local speed = 60  -- pixels per second

            if love.keyboard.isDown(input.keyMap.up) then
                velocity.dy = -speed
            elseif love.keyboard.isDown(input.keyMap.down) then
                velocity.dy = speed
            end

            if love.keyboard.isDown(input.keyMap.left) then
                velocity.dx = -speed
            elseif love.keyboard.isDown(input.keyMap.right) then
                velocity.dx = speed
            end
        end
    end
end

-- Event System: Key Press Handling
ExampleSystems.KeyPressSystem = setmetatable({}, {__index = Systems.EventSystem})
ExampleSystems.KeyPressSystem.__index = ExampleSystems.KeyPressSystem

function ExampleSystems.KeyPressSystem.new()
    local system = Systems.EventSystem.new()
    setmetatable(system, ExampleSystems.KeyPressSystem)
    return system
end

function ExampleSystems.KeyPressSystem:init(ecs)
    Systems.EventSystem.init(self, ecs)
    return self
end

function ExampleSystems.KeyPressSystem:run(event)
    -- Only handle 'keypressed' events
    if event.type ~= "keypressed" then
        return
    end

    -- Handle different key presses
    if event.key == "escape" then
        love.event.quit()
    end
end

return ExampleSystems
