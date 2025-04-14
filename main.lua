-- main.lua
-- Entry point for Love2D GameBoy-style game using our ECS with scene management

---@diagnostic disable-next-line: undefined-global
local ECS = require("ECS.core")
local Renderer = require("ECS.renderer")
local SceneManager = require("ECS.scene_manager").SceneManager
local ExampleScenes = require("example_scenes")
local Transition = require("ECS.transition")

-- Game constants
local SCREEN_WIDTH = 160
local SCREEN_HEIGHT = 144
local SCALE = 8
local FONT_SCALE = 0.5

-- Game settings
local TRANSITION_DURATION = 0.75  -- Default transition duration (in seconds)

-- Game variables
local renderer

function love.load()
    -- Set up the window with pixel-perfect settings
    love.window.setTitle("GameBoy Style ECS Game with Scenes")
    love.window.setMode(SCREEN_WIDTH * SCALE, SCREEN_HEIGHT * SCALE, {
        vsync = true,
        resizable = false,
        minwidth = SCREEN_WIDTH,
        minheight = SCREEN_HEIGHT
    })
    
    -- Set global pixel rendering settings
    love.graphics.setDefaultFilter("nearest", "nearest")
    love.graphics.setLineStyle("rough")

    -- Create renderer
    renderer = Renderer.new(SCREEN_WIDTH, SCREEN_HEIGHT, SCALE, FONT_SCALE)
    
    -- Initialize scene manager with ECS and viewport dimensions
    SceneManager:init(ECS, SCREEN_WIDTH, SCREEN_HEIGHT)

    -- Create scenes
    ExampleScenes.createOverworldScene(SceneManager, ECS)
    ExampleScenes.createHouseScene(SceneManager, ECS)
    ExampleScenes.createBattleScene(SceneManager, ECS)

    -- Set the default transition duration
    Transition.duration = TRANSITION_DURATION
    
    -- Enable debug output for transitions
    Transition.debug = true

    -- Start with the overworld scene with a fade-in
    SceneManager:transitionToScene("overworld")
    Transition:start("fade_in", nil, false, TRANSITION_DURATION)
    
    -- Print debug info
    print("Game initialized")
    print("Transition duration: " .. TRANSITION_DURATION)
end

function love.update(dt)
    -- Run all update systems for the current scene
    SceneManager:update(dt)
end


function love.draw()
    -- Begin rendering
    renderer:begin()
    
    -- Set the camera from the active scene
    if SceneManager.activeScene then
        renderer:setCamera(SceneManager.activeScene.camera)
    end

    -- Run all render systems for the current scene
    SceneManager:render(renderer)

    -- End rendering to canvas
    renderer:end_drawing()

    -- Draw canvas to screen
    renderer:draw_to_screen()

    -- For debugging - show current scene name and transition state using the pixel font
    -- First save the current font
    local previousFont = love.graphics.getFont()
    love.graphics.setFont(renderer.pixelFont)
    
    love.graphics.setColor(1, 1, 1)
    if SceneManager.activeScene then
        love.graphics.print("Scene: " .. SceneManager.activeScene.name, 10, 5)
        
        -- Display camera and world info in debug text
        local camera = SceneManager.activeScene.camera
        local world = SceneManager.activeScene.world
        
        love.graphics.print(string.format("Camera: %.0f,%.0f", camera.x, camera.y), 10, 25)
        love.graphics.print(string.format("World: %dx%d", world.width, world.height), 10, 45)
        
        if Transition.active then
            love.graphics.print("Transition: " .. Transition.type .. " (Level: " .. Transition.fadeLevel .. ")", 10, 65)
            love.graphics.print("Input Locked: " .. (Transition.inputLocked and "Yes" or "No"), 10, 85)
        else
            love.graphics.print("Transition: None", 10, 65)
            love.graphics.print("Input Locked: " .. (Transition.inputLocked and "Yes" or "No"), 10, 85)
        end
    end
    
    -- Restore the previous font
    love.graphics.setFont(previousFont)
end

function love.keypressed(key, scancode, isrepeat)
    -- Create event for scene manager (will be skipped if input is locked)
    local event = {
        type = "keypressed",
        key = key,
        scancode = scancode,
        isrepeat = isrepeat
    }

    SceneManager:handleEvent(event)
    
    -- Camera debug controls (WASD to move camera)
    if SceneManager.activeScene and not Transition:isInputLocked() then
        local camera = SceneManager.activeScene.camera
        local moveAmount = 10
        
        if key == "w" then
            camera:move(0, -moveAmount)
        elseif key == "s" then
            camera:move(0, moveAmount)
        elseif key == "a" then
            camera:move(-moveAmount, 0)
        elseif key == "d" then
            camera:move(moveAmount, 0)
        elseif key == "c" then
            -- Center camera on player
            local playerEntities = ECS:getEntitiesWithComponent("player")
            if #playerEntities > 0 then
                local player = playerEntities[1]
                local transform = player:getComponent("transform")
                if transform then
                    camera:centerOn(transform.x, transform.y)
                    print("Centered camera on player at " .. transform.x .. "," .. transform.y)
                end
            end
        end
    end

    -- Debug scene transitions with number keys
    -- These will still work even if normal input is locked
    if key == "1" then
        print("Transitioning to overworld")
        SceneManager:transitionToSceneWithFade("overworld", true, TRANSITION_DURATION)
    elseif key == "2" then
        print("Transitioning to house")
        SceneManager:transitionToSceneWithFade("house", true, TRANSITION_DURATION)
    elseif key == "3" then
        print("Transitioning to battle")
        SceneManager:transitionToSceneWithFade("battle", true, TRANSITION_DURATION)
    elseif key == "0" then
        print("Returning to previous scene")
        SceneManager:returnToPreviousSceneWithFade(TRANSITION_DURATION)
    elseif key == "f" then
        -- Force a manual fade in/out for testing
        if not Transition.active then
            print("Forcing fade out and in")
            Transition:start("fade_out", nil, false, TRANSITION_DURATION)
        end
    elseif key == "r" then
        -- Reset transition state (emergency fix for stuck transitions)
        print("Resetting transition state")
        Transition.active = false
        Transition.inputLocked = false
        Transition.waitForNextFrame = false
    end
end

function love.keyreleased(key, scancode)
    -- Skip if input is locked during transitions
    if Transition:isInputLocked() then return end
    
    -- Create event and pass to scene manager
    local event = {
        type = "keyreleased",
        key = key,
        scancode = scancode
    }

    SceneManager:handleEvent(event)
end
