-- create_ldtk_scene.lua
local Core = require("ECS.core")
local LDtk = require("ECS.ldtk")

local LDtkScene = {}
LDtkScene.__index = LDtkScene

---@param sceneManager table
---@param ecs table
---@param sceneName string
---@param viewportWidth number
---@param viewportHeight number
---@param levelId string
---@return LDtkScene
function LDtkScene.new(sceneManager, ecs, sceneName, viewportWidth, viewportHeight, levelId)
    local self = setmetatable({}, LDtkScene)

    self.sceneManager = sceneManager
    self.ecs = ecs
    self.sceneName = sceneName
    self.viewportWidth = viewportWidth
    self.viewportHeight = viewportHeight
    self.levelId = levelId

    -- Create the scene
    self.scene = sceneManager:createScene(sceneName, viewportWidth, viewportHeight)

    -- Initialize the world from LDtk level
    sceneManager:initWorldFromLDtk(self.scene, levelId)

    -- Setup basic systems (excluding example systems)
    self:setupBasicSystems()

    return self
end

-- Setup the basic systems common to all LDtk scenes
function LDtkScene:setupBasicSystems()
    local scene = self.scene
    local ecs = self.ecs
    local levelId = self.levelId

    -- Setup systems in the correct order

    -- Core setup systems
    scene:addSystem("setup", Core.SceneInitSystem.new():init(ecs, true, 0.5))
    scene:addSystem("setup", Core.TextureLoadSystem.new():init(ecs))
    scene:addSystem("setup", LDtk.TilesetPreloadSystem.new():init(ecs))

    -- Core update systems
    scene:addSystem("update", Core.ColliderSystem.new():init(ecs, levelId))
    scene:addSystem("update", Core.PlayerAnimationSystem.new():init(ecs))
    scene:addSystem("update", Core.MovementSystem.new():init(ecs))
    scene:addSystem("update", Core.CameraSystem.new():init(ecs, scene.camera))
    scene:addSystem("update", Core.GridSyncSystem.new():init(ecs, scene.camera))

    -- Core render systems
    scene:addSystem("render", LDtk.TilemapRenderSystem.new():init(ecs, levelId))
    scene:addSystem("render", Core.SpriteRenderSystem.new():init(ecs))

    -- Additional render systems (optional, can be overridden)
end

return LDtkScene

