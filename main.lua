-- main.lua
-- Simple entry point for Love2D game using ECS with scene management

-- Import required modules
local ECS = require("ECS.ecs")
local Renderer = require("ECS.renderer")
local SceneManager = require("ECS.scene_manager").SceneManager
local ExampleScenes = require("example_scenes")
local TextureManager = require("ECS.texture_manager")
local Transition = require("ECS.transition")

-- Game constants
local SCREEN_WIDTH = 160
local SCREEN_HEIGHT = 144
local SCALE = 8
local FONT_SCALE = 0.5
local TRANSITION_DURATION = 0.5

-- Game variables
local renderer

function love.load()
    -- Set up the window
    love.window.setTitle("GameBoy Style ECS Game")
    love.window.setMode(SCREEN_WIDTH * SCALE, SCREEN_HEIGHT * SCALE, {
        vsync = true,
        resizable = false,
        minwidth = SCREEN_WIDTH,
        minheight = SCREEN_HEIGHT
    })
    
    -- Set pixel rendering settings
    love.graphics.setDefaultFilter("nearest", "nearest")
    love.graphics.setLineStyle("rough")

    -- Initialize TextureManager
    TextureManager.init(nil, true) -- nil for default color map, true for debug mode
    
    -- Create renderer
    renderer = Renderer.new(SCREEN_WIDTH, SCREEN_HEIGHT, SCALE, FONT_SCALE)
    
    -- Initialize scene manager
    SceneManager:init(ECS, SCREEN_WIDTH, SCREEN_HEIGHT)

    -- Create scenes
    ExampleScenes.createOverworldScene(SceneManager, ECS)

    -- Set default transition duration
    Transition.duration = TRANSITION_DURATION
    
    -- Start with the overworld scene
    SceneManager:transitionToScene("overworld")
    Transition:start("fade_in", nil, false, TRANSITION_DURATION)
    
    print("Game initialized with screen size: " .. SCREEN_WIDTH .. "x" .. SCREEN_HEIGHT)
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
        love.graphics.print("Current Scene: " .. SceneManager.activeScene.name, 10, 10)
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
