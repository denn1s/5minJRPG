-- example_systems.lua
-- Example systems for a simple game with sprites

local Systems = require("ECS.systems")
local Components = require("ECS.components")
local LDtkManager = require("ECS.ldtk.ldtk_manager")
local dump = require("libs.dump")

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
    self.ldtk = LDtkManager.getInstance()
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

ExampleSystems.DoorRenderSystem = setmetatable({}, {__index = Systems.RenderSystem})
ExampleSystems.DoorRenderSystem.__index = ExampleSystems.DoorRenderSystem

function ExampleSystems.DoorRenderSystem.new()
    local system = Systems.RenderSystem.new()
    setmetatable(system, ExampleSystems.DoorRenderSystem)
    return system
end

function ExampleSystems.DoorRenderSystem:init(ecs, currentLevel)
    Systems.RenderSystem.init(self, ecs)
    self.ldtk = LDtkManager.getInstance()
    self.currentLevel = currentLevel
    print("[DoorRenderSystem] Initialized for level: " .. tostring(currentLevel))
    return self
end

function ExampleSystems.DoorRenderSystem:run(renderer)
    local level = self.ldtk:getLevel(self.currentLevel)
    if not level then
        print("[DoorRenderSystem] ERROR: Level not found: " .. tostring(self.currentLevel))
        return
    end

    if not level.layerInstances then
        print("[DoorRenderSystem] No layers in level: " .. tostring(self.currentLevel))
        return
    end

    -- Find the Doors entity layer
    local doorsLayer = nil
    for _, layer in ipairs(level.layerInstances) do
        if layer.__type == "Entities" and layer.__identifier == "Doors" then
            doorsLayer = layer
            break
        end
    end

    if not doorsLayer then
        print("[DoorRenderSystem] Doors layer not found in level: " .. tostring(self.currentLevel))
        return
    end

    -- Iterate over each door entity in the Doors layer
    for _, doorEntity in ipairs(doorsLayer.entityInstances) do
        local px = doorEntity.px[1] or 0
        local py = doorEntity.px[2] or 0
        local width = doorEntity.width or 0
        local height = doorEntity.height or 0

        -- Draw filled rectangle for the door area
        renderer:draw_rectangle(px, py, width, height, 4, true) -- color index 4, filled

        -- Print door properties for debugging
        -- print("[DoorRenderSystem] Door entity properties:")
        -- dump.print(doorEntity.fieldInstances or {})
    end
end

ExampleSystems.LevelTransitionInputSystem = setmetatable({}, { __index = Systems.UpdateSystem })
ExampleSystems.LevelTransitionInputSystem.__index = ExampleSystems.LevelTransitionInputSystem

function ExampleSystems.LevelTransitionInputSystem.new()
    local system = Systems.UpdateSystem.new()
    setmetatable(system, ExampleSystems.LevelTransitionInputSystem)
    return system
end

function ExampleSystems.LevelTransitionInputSystem:init(ecs, sceneManager)
    Systems.UpdateSystem.init(self, ecs)
    self.ldtk = LDtkManager.getInstance()
    self.sceneManager = sceneManager
    return self
end

function ExampleSystems.LevelTransitionInputSystem:run(dt)
    local gridSize = self.ldtk:getGridSize()

    if love.keyboard.isDown("1") then
        -- Level_0, player at grid (5,5)
        local playerX = (5 + 1) * gridSize
        local playerY = (5 + 1) * gridSize
        local cameraX = playerX - self.sceneManager.viewportWidth / 2
        local cameraY = playerY - self.sceneManager.viewportHeight / 2

        self.sceneManager:transitionToSceneByLevelId(
            "Level_0",
            cameraX,
            cameraY,
            playerX,
            playerY,
            false, -- don't preserve current scene
            1.0    -- transition duration in seconds
        )
    elseif love.keyboard.isDown("2") then
        local playerX = (33 + 1) * gridSize
        local playerY = (2 + 1) * gridSize
        local cameraX = playerX - self.sceneManager.viewportWidth / 2
        local cameraY = playerY - self.sceneManager.viewportHeight / 2

        self.sceneManager:transitionToSceneByLevelId(
            "Level_1",
            cameraX,
            cameraY,
            playerX,
            playerY,
            false,
            1.0
        )
    elseif love.keyboard.isDown("3") then
        -- Level_3, player at grid (2,1)
        local playerX = (2 + 1) * gridSize
        local playerY = (1 + 1) * gridSize
        local cameraX = playerX - self.sceneManager.viewportWidth / 2
        local cameraY = playerY - self.sceneManager.viewportHeight / 2

        self.sceneManager:transitionToSceneByLevelId(
            "Level_2",
            cameraX,
            cameraY,
            playerX,
            playerY,
            false,
            1.0
        )
    end
end


return ExampleSystems
