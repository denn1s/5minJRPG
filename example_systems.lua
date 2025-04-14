-- example_systems.lua
-- Example systems for a simple game with sprites

local Systems = require("ECS.core")
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
    player:addComponent(Components.transform(80, 72))
    
    -- Add velocity component for movement
    player:addComponent(Components.velocity(0, 0))
    
    -- Add input component for player control
    player:addComponent(Components.input())
    
    -- Add collision component
    player:addComponent(Components.collision(6))
    
    -- Add player-specific component with stats
    player:addComponent({
        name = "player",
        health = 100,
        maxHealth = 100,
        experience = 0,
        level = 1
    })
    
    -- Mark player as persistent across scenes
    local SceneManager = require("ECS.scene_manager").SceneManager
    SceneManager:markEntityAsPersistent(player)
    
    print("Created player entity with texture: " .. heroSpritesheetPath)
    
    return player
end

-- Setup System: Create World Objects
ExampleSystems.CreateWorldSystem = setmetatable({}, {__index = Systems.SetupSystem})
ExampleSystems.CreateWorldSystem.__index = ExampleSystems.CreateWorldSystem

function ExampleSystems.CreateWorldSystem.new()
    local system = Systems.SetupSystem.new()
    setmetatable(system, ExampleSystems.CreateWorldSystem)
    return system
end

function ExampleSystems.CreateWorldSystem:init(ecs)
    Systems.SetupSystem.init(self, ecs)
    return self
end

function ExampleSystems.CreateWorldSystem:run()
    -- Create a tree
    local treeTexturePath = "assets/spritesheets/tree.png"
    
    local tree = self.ecs:createEntity()
    tree:addComponent(Components.texture(treeTexturePath))
    tree:addComponent(Components.sprite(treeTexturePath, 16, 24, 0, 0))
    tree:addComponent(Components.transform(120, 50))
    tree:addComponent(Components.collision(8))
    
    print("Created tree at (120, 50)")
    
    -- Create a rock
    local rockTexturePath = "assets/spritesheets/rock.png"
    
    local rock = self.ecs:createEntity()
    rock:addComponent(Components.texture(rockTexturePath))
    rock:addComponent(Components.sprite(rockTexturePath, 8, 8, 0, 0))
    rock:addComponent(Components.transform(50, 90))
    rock:addComponent(Components.collision(4))
    
    print("Created rock at (50, 90)")
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
            local speed = 30  -- pixels per second
            
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

-- Update System: Movement and Collision
ExampleSystems.MovementSystem = setmetatable({}, {__index = Systems.UpdateSystem})
ExampleSystems.MovementSystem.__index = ExampleSystems.MovementSystem

function ExampleSystems.MovementSystem.new()
    local system = Systems.UpdateSystem.new()
    setmetatable(system, ExampleSystems.MovementSystem)
    return system
end

function ExampleSystems.MovementSystem:init(ecs)
    Systems.UpdateSystem.init(self, ecs)
    return self
end

function ExampleSystems.MovementSystem:run(dt)
    -- Get the active scene to access world bounds
    local SceneManager = require("ECS.scene_manager").SceneManager
    local activeScene = SceneManager.activeScene
    if not activeScene then return end
    
    local world = activeScene.world
    
    -- Get all entities with both transform and velocity components
    local entities = self.ecs:getEntitiesWithComponent("velocity")
    
    for _, entity in ipairs(entities) do
        local transform = entity:getComponent("transform")
        local velocity = entity:getComponent("velocity")
        
        if transform and velocity then
            -- Store previous position for collision resolution
            local prevX, prevY = transform.x, transform.y
            
            -- Update position based on velocity
            transform.x = transform.x + velocity.dx * dt
            transform.y = transform.y + velocity.dy * dt
            
            -- Keep within world bounds
            if transform.x < 0 then
                transform.x = 0
            elseif transform.x > world.width then
                transform.x = world.width
            end
            
            if transform.y < 0 then
                transform.y = 0
            elseif transform.y > world.height then
                transform.y = world.height
            end
            
            -- Simple collision detection
            if entity:hasComponent("collision") then
                local entityCollision = entity:getComponent("collision")
                
                -- Check collision with other entities
                local collisionEntities = self.ecs:getEntitiesWithComponent("collision")
                
                for _, otherEntity in ipairs(collisionEntities) do
                    -- Skip self-collision
                    if otherEntity.id ~= entity.id then
                        local otherTransform = otherEntity:getComponent("transform")
                        local otherCollision = otherEntity:getComponent("collision")
                        
                        if otherTransform and otherCollision then
                            -- Distance-based collision check
                            local dx = transform.x - otherTransform.x
                            local dy = transform.y - otherTransform.y
                            local distance = math.sqrt(dx*dx + dy*dy)
                            local minDistance = entityCollision.radius + otherCollision.radius
                            
                            if distance < minDistance then
                                -- Collision detected, revert to previous position
                                transform.x = prevX
                                transform.y = prevY
                                break
                            end
                        end
                    end
                end
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
