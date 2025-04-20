-- example_systems.lua
-- Example systems for a simple game with sprites

local Systems = require("ECS.systems")
local Components = require("ECS.components")
local LDtkManager = require("ECS.ldtk.ldtk_manager")

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
    player:addComponent(Components.collider(14, 8, 1, 7, true))  -- true enables debug rendering

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

-- Event System: intgrid rendering
ExampleSystems.IntGridRenderSystem = setmetatable({}, {__index = Systems.RenderSystem})
ExampleSystems.IntGridRenderSystem.__index = ExampleSystems.IntGridRenderSystem

function ExampleSystems.IntGridRenderSystem.new()
    local system = Systems.RenderSystem.new()
    setmetatable(system, ExampleSystems.IntGridRenderSystem)
    return system
end

function ExampleSystems.IntGridRenderSystem:init(ecs, currentLevel)
    Systems.RenderSystem.init(self, ecs)
    self.ldtk = LDtkManager.getInstance()
    self.currentLevel = currentLevel
    print("[IntGridRenderSystem] Initializing for level: " .. currentLevel)
    return self
end

function ExampleSystems.IntGridRenderSystem:run(renderer)
    local level = self.ldtk:getLevel(self.currentLevel)
    if not level then
        print("[IntGridRenderSystem] ERROR: Level not found: " .. self.currentLevel)
        return
    end

    if not level.layerInstances then
        print("[IntGridRenderSystem] No layers to render in level: " .. self.currentLevel)
        return
    end

    local gridSize = self.ldtk:getGridSize()

    -- Find the Collision intgrid layer
    local collisionLayer = nil
    for _, layer in ipairs(level.layerInstances) do
        if layer.__type == "IntGrid" and layer.__identifier == "Collision" then
            collisionLayer = layer
            break
        end
    end

    if not collisionLayer then
        print("[IntGridRenderSystem] Collision layer not found in level: " .. self.currentLevel)
        return
    end

    local width = collisionLayer.__cWid
    local height = collisionLayer.__cHei
    local intGridCsv = collisionLayer.intGridCsv

    -- Iterate over each tile in the intgrid
    for i = 1, #intGridCsv do
        local value = intGridCsv[i]
        if value == 1 then  -- WALKABLE tile
            -- Calculate x, y position in pixels
            local x = ((i - 1) % width) * gridSize
            local y = math.floor((i - 1) / width) * gridSize

            -- Draw rectangle at (x, y) with size gridSize x gridSize
            renderer:draw_rectangle(
                x,
                y,
                gridSize,
                gridSize,
                2,    -- Color index 2 (dark color)
                false -- Not filled
            )
        end
    end
end

return ExampleSystems
