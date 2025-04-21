-- door_transition_system.lua
-- Update system to detect player standing inside door and trigger scene transition

local Systems = require("ECS.systems")
local LDtkManager = require("ECS.ldtk.ldtk_manager")

local DoorTransitionSystem = setmetatable({}, {__index = Systems.UpdateSystem})
DoorTransitionSystem.__index = DoorTransitionSystem

function DoorTransitionSystem.new(sceneManager)
    local system = Systems.UpdateSystem.new()
    setmetatable(system, DoorTransitionSystem)
    system.sceneManager = sceneManager
    return system
end

function DoorTransitionSystem:init(ecs, currentLevel)
    Systems.UpdateSystem.init(self, ecs)
    self.ldtk = LDtkManager.getInstance()
    self.currentLevel = currentLevel
    self.gridSize = self.ldtk:getGridSize()
    return self
end

-- Helper: Calculate intersection area between two rectangles
local function rectIntersectionArea(ax, ay, aw, ah, bx, by, bw, bh)
    local x_overlap = math.max(0, math.min(ax + aw, bx + bw) - math.max(ax, bx))
    local y_overlap = math.max(0, math.min(ay + ah, by + bh) - math.max(ay, by))
    return x_overlap * y_overlap
end

function DoorTransitionSystem:run(dt)
    local players = self.ecs:getEntitiesWithComponent("player")
    if #players == 0 then
        return
    end
    local player = players[1]

    local transform = player:getComponent("transform")
    local collider = player:getComponent("collider")

    if not (transform and collider) then
        return
    end

    local level = self.ldtk:getLevel(self.currentLevel)
    if not level or not level.layerInstances then
        return
    end

    -- Player collider rectangle in pixels
    local playerX = transform.x + collider.offsetX
    local playerY = transform.y + collider.offsetY
    local playerW = collider.width
    local playerH = collider.height
    local playerArea = playerW * playerH

    -- Find Doors entity layer
    local doorsLayer = nil
    for _, layer in ipairs(level.layerInstances) do
        if layer.__type == "Entities" and layer.__identifier == "Doors" then
            doorsLayer = layer
            break
        end
    end

    if not doorsLayer then
        return
    end

    for _, doorEntity in ipairs(doorsLayer.entityInstances) do
        local doorX = doorEntity.px[1] or 0
        local doorY = doorEntity.px[2] or 0
        local doorW = doorEntity.width or 0
        local doorH = doorEntity.height or 0

        local intersection = rectIntersectionArea(
            playerX,
            playerY,
            playerW,
            playerH,
            doorX,
            doorY,
            doorW,
            doorH
        )

        if intersection > playerArea * 0.5 then
            print(
                string.format(
                    "[DoorTransitionSystem] Touched a door at (%d, %d)",
                    doorX,
                    doorY
                )
            )
            -- More than 50% overlap, check door properties
            local fields = doorEntity.fieldInstances or {}

            local toLevel, toX, toY = nil, nil, nil

            for _, field in ipairs(fields) do
                if field.__identifier == "To" and field.__value then
                    toLevel = field.__value
                elseif field.__identifier == "x" and field.__value then
                    toX = field.__value
                elseif field.__identifier == "y" and field.__value then
                    toY = field.__value
                end
            end

            if toLevel and toX and toY then
                -- Calculate target player position in pixels
                local targetPlayerX = toX * self.gridSize
                local targetPlayerY = toY * self.gridSize

                -- Calculate camera position centered on player
                local cameraX = targetPlayerX - self.sceneManager.viewportWidth / 2
                local cameraY = targetPlayerY - self.sceneManager.viewportHeight / 2

                print(
                    string.format(
                        "[DoorTransitionSystem] Transitioning to %s at (%d, %d)",
                        toLevel,
                        toX,
                        toY
                    )
                )

                self.sceneManager:transitionToSceneByLevelId(
                    toLevel,
                    cameraX,
                    cameraY,
                    targetPlayerX,
                    targetPlayerY,
                    false,
                    1.0
                )

                -- Only transition once per update
                break
            end
        end
    end
end

return DoorTransitionSystem

