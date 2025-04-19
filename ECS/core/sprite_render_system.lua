-- ECS/systems/sprite_render_system.lua
-- System for rendering sprites from textures in the texture manager

local Systems = require("ECS.systems")
local TextureManager = require("ECS.texture_manager")

---@class SpriteRenderSystem : RenderSystem
---@field ecs table ECS instance
local SpriteRenderSystem = setmetatable({}, {__index = Systems.RenderSystem})
SpriteRenderSystem.__index = SpriteRenderSystem

---@return SpriteRenderSystem
function SpriteRenderSystem.new()
    local system = Systems.RenderSystem.new()
    setmetatable(system, SpriteRenderSystem)
    return system
end

---@param ecs table
---@return SpriteRenderSystem
function SpriteRenderSystem:init(ecs)
    Systems.RenderSystem.init(self, ecs)
    return self
end

---@param renderer table
function SpriteRenderSystem:run(renderer)
    -- Get all entities with sprite components
    local entities = self.ecs:getEntitiesWithComponent("sprite")

    -- Get camera from the renderer
    local camera = renderer.camera

    for _, entity in ipairs(entities) do
        local transform = entity:getComponent("transform")
        local sprite = entity:getComponent("sprite")

        if transform and sprite and (sprite.visible == nil or sprite.visible) then
            -- Skip rendering if the entity is outside the camera view
            if camera then
                -- Check if the entity is visible in the camera's view
                local isVisible = camera:isRectVisible(
                    transform.x,
                    transform.y,
                    sprite.width,
                    sprite.height
                )

                if not isVisible then
                    -- Skip rendering entities outside the camera view
                    print("entity is not visible")
                    print("[SpriteRenderSystem] camera.x " .. camera.x)
                    print("[SpriteRenderSystem] camera.x " .. camera.y)
                    print("[SpriteRenderSystem] transform.x " .. transform.x)
                    print("[SpriteRenderSystem] transform.y " .. transform.y)
                    print("[SpriteRenderSystem] transform.gridX " .. transform.gridX)
                    print("[SpriteRenderSystem] transform.gridY " .. transform.gridY)
                    goto continue
                end
            end

            -- Get texture data from texture manager using the texture path
            if sprite.texturePath then
                local textureData, _, _ = TextureManager.getTexture(sprite.texturePath)

                if textureData then
                    -- Draw the specific sprite from the texture
                    self:drawSpritefromSheet(
                        renderer,
                        textureData,
                        transform.x,
                        transform.y,
                        sprite.width,
                        sprite.height,
                        sprite.xIndex,
                        sprite.yIndex
                    )
                    print(
                        string.format("Sprite %s: (%s, %s) [%s, %s]",
                            sprite.texturePath,
                            transform.gridX,
                            transform.gridY,
                            math.floor(transform.x),
                            math.floor(transform.y)
                        )
                    )
                else
                    -- Fallback to draw a placeholder if texture not found in cache
                    self:drawPlaceholder(renderer, transform.x, transform.y)

                    -- Print warning that the texture wasn't found
                    print("SpriteRenderSystem: Texture not found for entity " .. entity.id ..
                          ": " .. sprite.texturePath)
                end
            else
                -- No texture path specified
                self:drawPlaceholder(renderer, transform.x, transform.y)
                print("SpriteRenderSystem: No texture path for entity " .. entity.id)
            end
        end

        ::continue::
    end
end

---@param renderer table
---@param x number
---@param y number
function SpriteRenderSystem:drawPlaceholder(renderer, x, y)
    -- Simple placeholder for missing textures
    local screenX, screenY = renderer:worldToScreen(x, y)
    love.graphics.setColor(renderer.COLORS[2]) -- Dark color
    love.graphics.rectangle("line", screenX, screenY, 16, 16)
    love.graphics.line(screenX, screenY, screenX + 16, screenY + 16)
    love.graphics.line(screenX + 16, screenY, screenX, screenY + 16)
end

---@param renderer table
---@param textureData table
---@param x number
---@param y number
---@param width number
---@param height number
---@param xIndex number
---@param yIndex number
function SpriteRenderSystem:drawSpritefromSheet(renderer, textureData, x, y, width, height, xIndex, yIndex)
    -- Convert world coordinates to screen coordinates using the renderer's camera
    local screenX, screenY = renderer:worldToScreen(x, y)

    -- Calculate the starting position in the spritesheet
    local startX = xIndex * width + 1  -- +1 because Lua arrays are 1-indexed
    local startY = yIndex * height + 1

    -- Draw sprite pixel by pixel
    for dy = 0, height - 1 do
        local srcY = startY + dy
        if textureData[srcY] then  -- Check if row exists
            for dx = 0, width - 1 do
                local srcX = startX + dx

                if textureData[srcY][srcX] and textureData[srcY][srcX] > 0 then
                    -- Get the color index from the texture data
                    local pixelColorIndex = textureData[srcY][srcX]

                    -- Calculate the target position, applying flipping if needed
                    local targetX = dx
                    local targetY = dy

                    -- Draw the pixel at the screen position
                    love.graphics.setColor(renderer.COLORS[pixelColorIndex])
                    love.graphics.points(math.floor(screenX + targetX), math.floor(screenY + targetY))
                end
            end
        end
    end
end

return SpriteRenderSystem
