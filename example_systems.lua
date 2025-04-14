-- example_systems.lua
-- Example systems for the ECS

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

function ExampleSystems.CreatePlayerSystem:run()
    local Components = require("ECS.components")

    -- Create player entity and store reference
    local player = self.ecs:createEntity()
        :addComponent(Components.transform(80, 72))  -- Middle of the screen
        :addComponent(Components.velocity(0, 0))
        :addComponent(Components.input())
        :addComponent(Components.collision(2))

    -- Add player-specific component
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
end

-- Setup System: Create Overworld
ExampleSystems.CreateOverworldSystem = setmetatable({}, {__index = Systems.SetupSystem})
ExampleSystems.CreateOverworldSystem.__index = ExampleSystems.CreateOverworldSystem

function ExampleSystems.CreateOverworldSystem.new()
    local system = Systems.SetupSystem.new()
    setmetatable(system, ExampleSystems.CreateOverworldSystem)
    return system
end

function ExampleSystems.CreateOverworldSystem:run()
    local Components = require("ECS.components")

    self.ecs:createEntity()
        :addComponent(Components.transform(120, 50))
        :addComponent(Components.collision(3))
        :addComponent({
            name = "portal",
            targetScene = "house",
            enterX = 80,
            enterY = 100
        })

    -- Create battle trigger area
    self.ecs:createEntity()
        :addComponent(Components.transform(40, 50))
        :addComponent({
            name = "battleTrigger",
            encounterRate = 0.1, -- 10% chance per update when player inside
            battleRadius = 15,
            cooldown = 0,
            cooldownMax = 3 -- Seconds between battle checks
        })
end

-- Setup System: Create House
ExampleSystems.CreateHouseSystem = setmetatable({}, {__index = Systems.SetupSystem})
ExampleSystems.CreateHouseSystem.__index = ExampleSystems.CreateHouseSystem

function ExampleSystems.CreateHouseSystem.new()
    local system = Systems.SetupSystem.new()
    setmetatable(system, ExampleSystems.CreateHouseSystem)
    return system
end

function ExampleSystems.CreateHouseSystem:run()
    local Components = require("ECS.components")

    -- Create exit door
    self.ecs:createEntity()
        :addComponent(Components.transform(80, 120))
        :addComponent(Components.collision(2))
        :addComponent({
            name = "portal",
            targetScene = "overworld",
            enterX = 120,
            enterY = 60
        })

    -- Create table
    self.ecs:createEntity()
        :addComponent(Components.transform(60, 50))
        :addComponent(Components.collision(2))
        :addComponent({
            name = "interactable",
            message = "A sturdy wooden table."
        })
end

-- Setup System: Create Battle
ExampleSystems.CreateBattleSystem = setmetatable({}, {__index = Systems.SetupSystem})
ExampleSystems.CreateBattleSystem.__index = ExampleSystems.CreateBattleSystem

function ExampleSystems.CreateBattleSystem.new()
    local system = Systems.SetupSystem.new()
    setmetatable(system, ExampleSystems.CreateBattleSystem)
    return system
end

function ExampleSystems.CreateBattleSystem:run()
    local Components = require("ECS.components")

    -- Create enemy
    self.ecs:createEntity()
        :addComponent(Components.transform(80, 40))
        :addComponent({
            name = "enemy",
            health = 50,
            maxHealth = 50,
            attack = 5,
            defense = 2,
            experienceValue = 10
        })

    -- Create battle UI elements
    self.ecs:createEntity()
        :addComponent({
            name = "battleUI",
            state = "select", -- select, attack, item, victory, defeat
            selectedOption = 1,
            options = {"Attack", "Item", "Run"},
            message = "A wild enemy appears!"
        })
end

ExampleSystems.MovementSystem = setmetatable({}, {__index = Systems.UpdateSystem})
ExampleSystems.MovementSystem.__index = ExampleSystems.MovementSystem

function ExampleSystems.MovementSystem.new()
    local system = Systems.UpdateSystem.new()
    setmetatable(system, ExampleSystems.MovementSystem)
    return system
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
        local sprite = entity:getComponent("sprite")

        if transform and velocity then
            -- Store previous position for collision resolution
            local prevX, prevY = transform.x, transform.y

            -- Update position based on velocity
            transform.x = transform.x + velocity.dx * dt
            transform.y = transform.y + velocity.dy * dt

            -- Get entity dimensions if it has a sprite
            local width, height = 1, 1
            if sprite then
                width = sprite.width
                height = sprite.height
            end

            -- Keep within world bounds
            if transform.x < 0 then
                transform.x = 0
            elseif transform.x + width > world.width then
                transform.x = world.width - width
            end

            if transform.y < 0 then
                transform.y = 0
            elseif transform.y + height > world.height then
                transform.y = world.height - height
            end

            -- Simple collision detection with other entities
            local collision = entity:getComponent("collision")
            if collision and collision.solid then
                local collisionEntities = self.ecs:getEntitiesWithComponent("collision")

                for _, otherEntity in ipairs(collisionEntities) do
                    -- Skip self-collision
                    if otherEntity.id ~= entity.id then
                        local otherTransform = otherEntity:getComponent("transform")
                        local otherCollision = otherEntity:getComponent("collision")

                        if otherTransform and otherCollision and otherCollision.solid then
                            -- Simple distance-based collision detection
                            local dx = transform.x - otherTransform.x
                            local dy = transform.y - otherTransform.y
                            local distance = math.sqrt(dx*dx + dy*dy)
                            local minDistance = collision.radius + otherCollision.radius

                            if distance < minDistance then
                                -- Collision detected, revert position
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

-- Update System: Input with transition awareness
ExampleSystems.InputSystem = setmetatable({}, {__index = Systems.UpdateSystem})
ExampleSystems.InputSystem.__index = ExampleSystems.InputSystem

function ExampleSystems.InputSystem.new()
    local system = Systems.UpdateSystem.new()
    setmetatable(system, ExampleSystems.InputSystem)
    return system
end

function ExampleSystems.InputSystem:run(dt)
    -- Get the transition state to check if input is locked
    local Transition = require("ECS.transition")

    -- If input is locked during transition, don't process input
    if Transition:isInputLocked() then return end

    -- Get all entities with input component
    local entities = self.ecs:getEntitiesWithComponent("input")

    for _, entity in ipairs(entities) do
        local input = entity:getComponent("input")
        local velocity = entity:getComponent("velocity")

        if input and velocity then
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

-- Update System: Overworld Interaction with fade transitions
ExampleSystems.OverworldInteractionSystem = setmetatable({}, {__index = Systems.UpdateSystem})
ExampleSystems.OverworldInteractionSystem.__index = ExampleSystems.OverworldInteractionSystem

function ExampleSystems.OverworldInteractionSystem.new()
    local system = Systems.UpdateSystem.new()
    setmetatable(system, ExampleSystems.OverworldInteractionSystem)
    return system
end

function ExampleSystems.OverworldInteractionSystem:run(dt)
    local SceneManager = require("ECS.scene_manager").SceneManager
    local Transition = require("ECS.transition")

    -- If a transition is in progress, don't process interactions
    if Transition:isInputLocked() then return end

    -- Get player entity
    local playerEntities = self.ecs:getEntitiesWithComponent("player")
    if #playerEntities == 0 then return end
    local player = playerEntities[1]
    local playerTransform = player:getComponent("transform")

    -- Check for portal interactions (entrances/exits)
    local portalEntities = self.ecs:getEntitiesWithComponent("portal")
    for _, portalEntity in ipairs(portalEntities) do
        local portalTransform = portalEntity:getComponent("transform")
        local portal = portalEntity:getComponent("portal")
        local collisionComponent = portalEntity:getComponent("collision")

        -- Calculate distance between player and portal
        local dx = playerTransform.x - portalTransform.x
        local dy = playerTransform.y - portalTransform.y
        local distance = math.sqrt(dx*dx + dy*dy)

        -- If player is close enough to portal and pressing action key
        if distance < (collisionComponent and collisionComponent.radius or 5) and
           love.keyboard.isDown("z") then
            -- Update player position for the new scene
            playerTransform.x = portal.enterX
            playerTransform.y = portal.enterY

            -- Transition to the new scene with fade
            SceneManager:transitionToSceneWithFade(portal.targetScene, true)
        end
    end

    -- Check for battle triggers
    local battleTriggers = self.ecs:getEntitiesWithComponent("battleTrigger")
    for _, triggerEntity in ipairs(battleTriggers) do
        local triggerTransform = triggerEntity:getComponent("transform")
        local trigger = triggerEntity:getComponent("battleTrigger")

        -- Update cooldown
        trigger.cooldown = math.max(0, trigger.cooldown - dt)

        -- If cooldown is done, check for battle
        if trigger.cooldown <= 0 then
            -- Calculate distance between player and trigger
            local dx = playerTransform.x - triggerTransform.x
            local dy = playerTransform.y - triggerTransform.y
            local distance = math.sqrt(dx*dx + dy*dy)

            -- If player is inside battle radius
            if distance < trigger.battleRadius then
                -- Random chance for encounter
                if love.math.random() < trigger.encounterRate then
                    -- Start battle with fade transition
                    SceneManager:transitionToSceneWithFade("battle", true)

                    -- Reset cooldown
                    trigger.cooldown = trigger.cooldownMax
                end
            end
        end
    end
end

-- Update System: House Interaction with fade transitions
ExampleSystems.HouseInteractionSystem = setmetatable({}, {__index = Systems.UpdateSystem})
ExampleSystems.HouseInteractionSystem.__index = ExampleSystems.HouseInteractionSystem

function ExampleSystems.HouseInteractionSystem.new()
    local system = Systems.UpdateSystem.new()
    setmetatable(system, ExampleSystems.HouseInteractionSystem)
    return system
end

function ExampleSystems.HouseInteractionSystem:run(dt)
    local Transition = require("ECS.transition")

    -- If a transition is in progress, don't process interactions
    if Transition:isInputLocked() then return end

    -- Get player entity
    local playerEntities = self.ecs:getEntitiesWithComponent("player")
    if #playerEntities == 0 then return end
    local player = playerEntities[1]
    local playerTransform = player:getComponent("transform")

    -- Check for portal interactions (exits)
    local portalEntities = self.ecs:getEntitiesWithComponent("portal")
    for _, portalEntity in ipairs(portalEntities) do
        local portalTransform = portalEntity:getComponent("transform")
        local portal = portalEntity:getComponent("portal")
        local collision = portalEntity:getComponent("collision")

        -- Calculate distance
        local dx = playerTransform.x - portalTransform.x
        local dy = playerTransform.y - portalTransform.y
        local distance = math.sqrt(dx*dx + dy*dy)

        -- If player is close and pressing action key
        if distance < (collision and collision.radius or 5) and love.keyboard.isDown("z") then
            -- Update player position for the new scene
            playerTransform.x = portal.enterX
            playerTransform.y = portal.enterY

            -- Transition to the new scene with fade
            local SceneManager = require("ECS.scene_manager").SceneManager
            SceneManager:transitionToSceneWithFade(portal.targetScene, true)
        end
    end

    -- Check for interactable objects
    local interactables = self.ecs:getEntitiesWithComponent("interactable")
    for _, entity in ipairs(interactables) do
        local transform = entity:getComponent("transform")
        local interactable = entity:getComponent("interactable")
        local collision = entity:getComponent("collision")

        -- Calculate distance
        local dx = playerTransform.x - transform.x
        local dy = playerTransform.y - transform.y
        local distance = math.sqrt(dx*dx + dy*dy)

        -- If player is close and pressing action key
        if distance < (collision and collision.radius or 5) and
           love.keyboard.isDown("z") and not interactable.messageShown then
            -- Show message (in a real game, you'd have a UI system for this)
            print(interactable.message)
            interactable.messageShown = true
        elseif not love.keyboard.isDown("z") then
            interactable.messageShown = false
        end
    end
end

-- Update System: Battle Input
ExampleSystems.BattleInputSystem = setmetatable({}, {__index = Systems.UpdateSystem})
ExampleSystems.BattleInputSystem.__index = ExampleSystems.BattleInputSystem

function ExampleSystems.BattleInputSystem.new()
    local system = Systems.UpdateSystem.new()
    setmetatable(system, ExampleSystems.BattleInputSystem)
    return system
end

function ExampleSystems.BattleInputSystem:run(dt)
    -- Get battle UI entity
    local uiEntities = self.ecs:getEntitiesWithComponent("battleUI")
    if #uiEntities == 0 then return end
    local ui = uiEntities[1]:getComponent("battleUI")

    -- Handle input based on current battle state
    if ui.state == "select" then
        -- Navigate options
        if love.keyboard.isDown("up") and not self.upPressed then
            ui.selectedOption = math.max(1, ui.selectedOption - 1)
            self.upPressed = true
        elseif not love.keyboard.isDown("up") then
            self.upPressed = false
        end

        if love.keyboard.isDown("down") and not self.downPressed then
            ui.selectedOption = math.min(#ui.options, ui.selectedOption + 1)
            self.downPressed = true
        elseif not love.keyboard.isDown("down") then
            self.downPressed = false
        end

        -- Select option
        if love.keyboard.isDown("z") and not self.zPressed then
            local option = ui.options[ui.selectedOption]
            if option == "Attack" then
                ui.state = "attack"
                ui.message = "Player attacks!"
            elseif option == "Item" then
                ui.state = "item"
                ui.message = "No items available."
            elseif option == "Run" then
                -- 50% chance to escape
                if love.math.random() < 0.5 then
                    ui.state = "escaped"
                    ui.message = "Got away safely!"
                else
                    ui.message = "Couldn't escape!"
                end
            end
            self.zPressed = true
        elseif not love.keyboard.isDown("z") then
            self.zPressed = false
        end
    elseif ui.state == "attack" or ui.state == "item" then
        -- Return to selection after pressing Z
        if love.keyboard.isDown("z") and not self.zPressed then
            ui.state = "select"
            self.zPressed = true
        elseif not love.keyboard.isDown("z") then
            self.zPressed = false
        end
    elseif ui.state == "victory" or ui.state == "defeat" or ui.state == "escaped" then
        -- Exit battle
        if love.keyboard.isDown("z") and not self.zPressed then
            local SceneManager = require("ECS.scene_manager").SceneManager
            SceneManager:returnToPreviousScene()
            self.zPressed = true
        elseif not love.keyboard.isDown("z") then
            self.zPressed = false
        end
    end
end

-- Update System: Battle Logic
ExampleSystems.BattleLogicSystem = setmetatable({}, {__index = Systems.UpdateSystem})
ExampleSystems.BattleLogicSystem.__index = ExampleSystems.BattleLogicSystem

function ExampleSystems.BattleLogicSystem.new()
    local system = Systems.UpdateSystem.new()
    setmetatable(system, ExampleSystems.BattleLogicSystem)
    return system
end

function ExampleSystems.BattleLogicSystem:run(dt)
    -- Get player entity
    local playerEntities = self.ecs:getEntitiesWithComponent("player")
    if #playerEntities == 0 then return end
    local player = playerEntities[1]
    local playerComponent = player:getComponent("player")

    -- Get enemy entity
    local enemyEntities = self.ecs:getEntitiesWithComponent("enemy")
    if #enemyEntities == 0 then return end
    local enemyEntity = enemyEntities[1]
    local enemy = enemyEntity:getComponent("enemy")

    -- Get battle UI entity
    local uiEntities = self.ecs:getEntitiesWithComponent("battleUI")
    if #uiEntities == 0 then return end
    local ui = uiEntities[1]:getComponent("battleUI")

    -- Handle battle logic based on state
    if ui.state == "attack" then
        -- Player deals damage to enemy
        local damage = math.max(1, 10 - enemy.defense)
        enemy.health = math.max(0, enemy.health - damage)

        -- Check if enemy is defeated
        if enemy.health <= 0 then
            ui.state = "victory"
            ui.message = "Victory! Gained " .. enemy.experienceValue .. " XP!"

            -- Give player experience
            playerComponent.experience = playerComponent.experience + enemy.experienceValue

            -- Check for level up (very simple level system)
            if playerComponent.experience >= playerComponent.level * 20 then
                playerComponent.level = playerComponent.level + 1
                playerComponent.maxHealth = playerComponent.maxHealth + 10
                playerComponent.health = playerComponent.maxHealth
                ui.message = ui.message .. " Level up! Now level " .. playerComponent.level .. "!"
            end
        else
            -- Enemy counterattack
            ui.state = "enemy_turn"
            ui.message = "Enemy counterattacks!"

            -- Enemy deals damage to player
            local damage = math.max(1, enemy.attack - 2)
            playerComponent.health = math.max(0, playerComponent.health - damage)

            -- Check if player is defeated
            if playerComponent.health <= 0 then
                ui.state = "defeat"
                ui.message = "Defeat! You fainted..."
            else
                -- Return to selection
                ui.state = "select"
            end
        end
    end
end

-- Render System: Sprite Renderer
ExampleSystems.SpriteRenderSystem = setmetatable({}, {__index = Systems.RenderSystem})
ExampleSystems.SpriteRenderSystem.__index = ExampleSystems.SpriteRenderSystem

function ExampleSystems.SpriteRenderSystem.new()
    local system = Systems.RenderSystem.new()
    setmetatable(system, ExampleSystems.SpriteRenderSystem)
    return system
end

function ExampleSystems.SpriteRenderSystem:run(renderer)
    -- Get all entities with both transform and sprite components
    local entities = self.ecs:getEntitiesWithComponent("sprite")

    for _, entity in ipairs(entities) do
        local transform = entity:getComponent("transform")
        local sprite = entity:getComponent("sprite")

        if transform and sprite then
            -- Draw the sprite at the entity's position
            renderer:draw_sprite(sprite.data, transform.x, transform.y, 1)  -- Using darkest color
        end
    end
end

-- Render System: Battle Renderer
ExampleSystems.BattleRenderSystem = setmetatable({}, {__index = Systems.RenderSystem})
ExampleSystems.BattleRenderSystem.__index = ExampleSystems.BattleRenderSystem

function ExampleSystems.BattleRenderSystem.new()
    local system = Systems.RenderSystem.new()
    setmetatable(system, ExampleSystems.BattleRenderSystem)
    return system
end

function ExampleSystems.BattleRenderSystem:run(renderer)
    -- First render sprites
    ExampleSystems.SpriteRenderSystem.new():init(self.ecs):run(renderer)

    -- testing text positioning
    renderer:draw_rectangle(5, 10, 150, 20, 1, false)

    renderer:draw_rectangle(80, 100, 70, 40, 1, false)

    renderer:draw_text("AAA", 0, 0, 1, 3)  -- this text should be in the upper left corner
    renderer:draw_text("BBB", 0, 4, 1, 3)  -- this should be right below
    renderer:draw_text("CCC", 80, 100, 1, 3) -- this should be inside the rectangle
    renderer:draw_text("DDD", 160/2, 144/2, 1, 3)  -- this should be in the middle of the screen
    renderer:draw_text("FFF", 160, 144, 1, 2)  -- this should not be on the screen
end

-- Event System: KeyPressed
ExampleSystems.KeyPressSystem = setmetatable({}, {__index = Systems.EventSystem})
ExampleSystems.KeyPressSystem.__index = ExampleSystems.KeyPressSystem

function ExampleSystems.KeyPressSystem.new()
    local system = Systems.EventSystem.new()
    setmetatable(system, ExampleSystems.KeyPressSystem)
    return system
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

    -- You could also handle other key events for entities with input components
end



-- Event System: KeyPressed
ExampleSystems.PlayerSetupSystem = setmetatable({}, {__index = Systems.SetupSystem})
ExampleSystems.PlayerSetupSystem.__index = ExampleSystems.PlayerSetupSystem

function ExampleSystems.PlayerSetupSystem.new()
    local system = Systems.SetupSystem.new()
    setmetatable(system, ExampleSystems.PlayerSetupSystem)
    return system
end

function ExampleSystems.PlayerSetupSystem:init(ecs, textureSystem)
    Systems.SetupSystem.init(self, ecs)
    self.textureSystem = textureSystem
    return self
end

function ExampleSystems.PlayerSetupSystem:run()
        -- Path to the player spritesheet
    local heroSpritesheetPath = "assets/spritesheets/hero.png"
    
    -- Create player entity
    local player = self.ecs:createEntity()
    
    -- Print current entity id for debugging
    print("Creating player with entity ID: " .. player.id)
    
    -- Add a texture component - TextureLoadSystem will handle loading it
    -- Make sure this component has name="texture" in its implementation
    player:addComponent(Components.texture(heroSpritesheetPath))
    
    -- Log the component to make sure it's what we expect
    local textureComp = player:getComponent("texture")
    if textureComp then
        print("Added texture component with path: " .. textureComp.path)
    else
        print("ERROR: Failed to add texture component!")
    end
    
    -- Add a sprite component to define which part of the texture to render
    -- Make sure the texture field is a string that matches the path
    player:addComponent(Components.sprite(heroSpritesheetPath, 16, 16, 0, 0))
    
    -- Log the sprite component
    local spriteComp = player:getComponent("sprite")
    if spriteComp then
        print("Added sprite component with texturePath: " .. (spriteComp.texturePath or "nil"))
    else
        print("ERROR: Failed to add sprite component!")
    end
    
    -- Add other necessary components
    player:addComponent(Components.transform(80, 72))  -- Start in middle of screen
    player:addComponent(Components.velocity(0, 0))
    player:addComponent(Components.input())
    player:addComponent(Components.collision(6))  -- Smaller collision radius than sprite size
    
    -- Add player-specific component
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
    
    -- Check if entity has the expected components
    print("Checking components on player entity...")
    local components = {}
    for name, _ in pairs(player.components) do
        table.insert(components, name)
    end
    print("Player components: " .. table.concat(components, ", "))
    
    print("Created player entity with reference to texture: " .. heroSpritesheetPath)
    
    return player
end

return ExampleSystems
