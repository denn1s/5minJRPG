-- main.lua
-- Simple entry point for Love2D game using ECS with scene management

-- Import required modules
local ECS = require("ECS.ecs")
local Renderer = require("ECS.renderer")
local Components = require("ECS.components")
local SceneManager = require("ECS.scene_manager")
local ExampleLDtkScene = require("example_ldtk_scene")
local TextureManager = require("ECS.texture_manager")
local LDtkManager = require("ECS.ldtk.ldtk_manager")
local Transition = require("ECS.transition")

-- Game constants
local SCREEN_WIDTH = 160
local SCREEN_HEIGHT = 144
local SCALE = 8
local FONT_SCALE = 0.5
local TRANSITION_DURATION = 0.5

-- Game variables
local renderer


function CreatePlayer()
    -- Path to the player spritesheet
    local heroSpritesheetPath = "assets/spritesheets/hero.png"

    -- Create player entity
    local player = ECS:createEntity()

    -- Add a texture component for loading the spritesheet
    player:addComponent(Components.texture(heroSpritesheetPath))

    -- Add a sprite component for rendering
    player:addComponent(Components.sprite(heroSpritesheetPath, 16, 16, 0, 0))

    -- Add transform component for position
    -- This is the initial player position in the initial scene, must be a walkable
    player:addComponent(Components.transform(65 * 8, 4 * 8))

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

function love.load()
    -- Set up the window
    love.window.setTitle("GameBoy Style ECS Game")
    love.window.setMode(SCREEN_WIDTH * SCALE, SCREEN_HEIGHT * SCALE, {
        vsync = false,
        resizable = false,
    })

    -- Set pixel rendering settings
    love.graphics.setDefaultFilter("nearest", "nearest")
    love.graphics.setLineStyle("rough")

    -- Create renderer
    renderer = Renderer.new(SCREEN_WIDTH, SCREEN_HEIGHT, SCALE, FONT_SCALE)

    -- -- Initialize scene manager
    SceneManager:init(ECS, SCREEN_WIDTH, SCREEN_HEIGHT)

    -- -- Initialize ldtk manager
    local ldtk = LDtkManager.new("assets/map.ldtk")
    ldtk:load()

    -- -- Create our LDtk scene
    ExampleLDtkScene.createLevel0(SceneManager, ECS)
    ExampleLDtkScene.createLevel1(SceneManager, ECS)
    ExampleLDtkScene.createLevel2(SceneManager, ECS)

    -- -- Set default transition duration
    Transition.duration = TRANSITION_DURATION

    -- Create player outside of any scene
    CreatePlayer()

    -- -- Start with the LDtk scene
    SceneManager:transitionToSceneByLevelId("Level_1", 500, 500, 65 * 8, 4 * 8, true, 0.5)
    -- SceneManager:transitionToScene("Level_1_Scene")
    Transition:start("fade_in", nil, false, TRANSITION_DURATION)

    print("[main] Game initialized with screen size: " .. SCREEN_WIDTH .. "x" .. SCREEN_HEIGHT .. "\n\n")
end

function love.update(dt)
    -- Run update systems for the current scene
    SceneManager:update(dt)
end

function love.draw()
    -- Begin rendering
    renderer:begin()

    -- Set the camera from the active scene
    if SceneManager.activeScene then
        renderer:setCamera(SceneManager.activeScene.camera)
    end

    -- Run render systems
    SceneManager:render(renderer)

    -- End drawing to canvas
    renderer:end_drawing()

    -- Draw canvas to screen
    renderer:draw_to_screen()

    -- Debug info
    love.graphics.setColor(1, 1, 1)
    if SceneManager.activeScene then
        local world = SceneManager.activeScene.world

        love.graphics.print("Current Scene: " .. SceneManager.activeScene.name, 10, 10)
        if world then
            love.graphics.print("Current World: " .. string.format(
                "/grid %s/gw %s/gh %s/pxw %s/pxh %s",
                world.gridSize, world.gridWidth, world.gridHeight, world.pixelWidth, world.pixelHeight
            ), 10, 22)
        end
        love.graphics.print("FPS: " .. love.timer.getFPS(), 10, 34)

        local playerEntities = ECS:getEntitiesWithComponent("player")
        for _, entity in ipairs(playerEntities) do
            local t = entity:getComponent("transform")

            love.graphics.print(
                "Player: " .. string.format("(%s, %s) [%s, %s]", math.floor(t.x), math.floor(t.y), t.gridX, t.gridY),
                10, 46
            )
        end
    end
end

function love.keypressed(key, scancode, isrepeat)
    -- Create event
    local event = {
        type = "keypressed",
        key = key,
        scancode = scancode,
        isrepeat = isrepeat
    }

    -- Pass event to scene manager
    SceneManager:handleEvent(event)

    -- Debug controls
    if key == "f12" then
        print("Texture cache statistics:")
        TextureManager.printCacheStats()
    elseif key == "f11" then
        -- Toggle debug information display
        if SceneManager.activeScene then
            for _, system in ipairs(SceneManager.activeScene.systems.render) do
                if system.__index == require("ECS.core.debug_system").__index then
                    system:toggleDebugInfo()
                    break
                end
            end
        end
    elseif key == "f1" or key == "f2" or key == "f3" then
        -- Level switching for testing
        local levelId = nil
        if key == "f1" then
            levelId = "Level_0"  -- Overworld/town
        elseif key == "f2" then
            levelId = "Level_1"  -- House interior
        elseif key == "f3" then
            levelId = "Level_2"  -- Dungeon
        end

        if levelId and SceneManager.activeScene and SceneManager.activeScene.name == "ldtk_scene" then
            -- Find the LDtk load system
            for _, system in ipairs(SceneManager.activeScene.systems.setup) do
                if system.__index == require("ECS.ldtk.ldtk_system").__index then
                    -- Load the new level
                    print("Switching to level: " .. levelId)
                    system:loadLevel(levelId, 10, 10)  -- Default player position in new level

                    -- Update the tilemap render system
                    for _, renderSystem in ipairs(SceneManager.activeScene.systems.render) do
                        if renderSystem.__index == require("ECS.ldtk.ldtk_tilemap_render_system").__index then
                            renderSystem:setLevel(levelId)
                            break
                        end
                    end
                    break
                end
            end
        end
    end
end

function love.keyreleased(key, scancode)
    -- Create event
    local event = {
        type = "keyreleased",
        key = key,
        scancode = scancode
    }

    -- Pass event to scene manager
    SceneManager:handleEvent(event)
end
