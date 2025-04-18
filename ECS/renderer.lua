-- ECS/renderer.lua
-- Renderer interface for the ECS

local Transition = require("ECS.transition")
local Renderer = {}
Renderer.__index = Renderer

-- Gameboy color palette (in grayscale)
Renderer.COLORS = {
    {15/255, 56/255, 15/255},   -- Darkest (Black)
    {48/255, 98/255, 48/255},   -- Dark Gray
    {139/255, 172/255, 15/255}, -- Light Gray
    {155/255, 188/255, 15/255}  -- Lightest (White)
}

function Renderer.new(width, height, scale, fontScale)
    local renderer = {
        width = width,
        height = height,
        scale = scale or 1,
        fontScale = fontScale or 0.5, -- Font scale factor relative to game scale
        canvas = love.graphics.newCanvas(width, height),
        -- Create a larger text canvas to accommodate scaled positions
        textCanvas = love.graphics.newCanvas(width / fontScale, height / fontScale),
        camera = nil -- Will be set by the scene manager
    }
    setmetatable(renderer, Renderer)

    -- Set up crisp pixel rendering globally
    love.graphics.setDefaultFilter("nearest", "nearest")

    -- Configure both canvases for pixel-perfect rendering
    renderer.canvas:setFilter("nearest", "nearest")
    renderer.textCanvas:setFilter("nearest", "nearest")

    -- Load the font at its native 8x8 size
    renderer.pixelFont = love.graphics.newFont("assets/fonts/pixelFontSharp.ttf", 8)
    renderer.pixelFont:setFilter("nearest", "nearest")

    return renderer
end

function Renderer:begin()
    -- Begin drawing to our game canvas
    love.graphics.setCanvas(self.canvas)

    -- Set pixel-perfect line style (no anti-aliasing)
    love.graphics.setLineStyle("rough")

    -- Clear with the lightest color (Gameboy "white")
    -- Use the fade-adjusted color for the background
    local adjustedColorIndex = Transition:getAdjustedColorIndex(1)
    love.graphics.setColor(self.COLORS[adjustedColorIndex])
    love.graphics.rectangle("fill", 0, 0, self.width, self.height)

    -- Clear the text canvas with transparent background
    love.graphics.setCanvas(self.textCanvas)
    love.graphics.clear(0, 0, 0, 0)

    -- Return to game canvas for normal rendering
    love.graphics.setCanvas(self.canvas)
end

function Renderer:end_drawing()
    -- Reset canvas
    love.graphics.setCanvas()
end

function Renderer:draw_to_screen()
    -- Calculate integer scaling factor for pixel-perfect rendering
    local scaleX = math.floor(love.graphics.getWidth() / self.width)
    local scaleY = math.floor(love.graphics.getHeight() / self.height)
    local gameScale = math.min(scaleX, scaleY)

    -- Center the scaled canvas on screen
    local offsetX = math.floor((love.graphics.getWidth() - (self.width * gameScale)) / 2)
    local offsetY = math.floor((love.graphics.getHeight() - (self.height * gameScale)) / 2)

    -- Draw game canvas
    love.graphics.setColor(1, 1, 1)
    love.graphics.draw(self.canvas, offsetX, offsetY, 0, gameScale, gameScale)

    -- Draw text canvas with the correct scale
    -- Since the text canvas is already scaled up in size, we apply both
    -- the fontScale and account for the canvas size difference
    local textScale = gameScale * self.fontScale
    love.graphics.draw(self.textCanvas, offsetX, offsetY, 0, textScale, textScale)
end

-- Set the camera reference for coordinate transformations
---@param camera table Camera
function Renderer:setCamera(camera)
    self.camera = camera
end

-- Convert world coordinates to screen coordinates
---@param x number
---@param y number
---@return number, number
function Renderer:worldToScreen(x, y)
    if self.camera then
        return x - self.camera.x, y - self.camera.y
    end
    return x, y
end

function Renderer:draw_rectangle(x, y, width, height, colorIndex, filled)
    -- Convert world coordinates to screen coordinates
    local screenX, screenY = self:worldToScreen(x, y)

    -- Apply the fade effect to the color index
    local adjustedColorIndex = Transition:getAdjustedColorIndex(colorIndex or 1)
    love.graphics.setColor(self.COLORS[adjustedColorIndex])

    -- Use math.floor to ensure we're drawing at exact pixel positions
    local drawMode = filled and "fill" or "line"
    love.graphics.rectangle(drawMode, math.floor(screenX), math.floor(screenY),
        math.floor(width), math.floor(height))
end

function Renderer:draw_sprite(sprite, x, y, colorIndex)
    -- Convert world coordinates to screen coordinates
    local screenX, screenY = self:worldToScreen(x, y)

    -- Apply the fade effect to the color index
    local adjustedColorIndex = Transition:getAdjustedColorIndex(colorIndex or 1)
    love.graphics.setColor(self.COLORS[adjustedColorIndex])

    -- Draw sprite (if it's an array of 0s and 1s)
    if type(sprite) == "table" then
        -- Use points for pixel-perfect drawing (aligns perfectly with pixel grid)
        for sy = 1, #sprite do
            local row = sprite[sy]
            for sx = 1, #row do
                if row[sx] == 1 then
                    -- Use math.floor to ensure we're drawing at exact pixel positions
                    love.graphics.points(math.floor(screenX + sx - 1), math.floor(screenY + sy - 1))
                end
            end
        end
    end
end

function Renderer:draw_text(text, x, y, textColorIndex, shadowColorIndex)
    -- For text, we have a special case:
    -- 1. If x and y are numbers, we treat them as world coordinates
    -- 2. If they're specific strings like "center", we handle special positioning
    local screenX, screenY

    if x == "center" then
        screenX = self.width / 2 - (text:len() * 4) -- Approximate center based on text length
    else
        screenX, screenY = self:worldToScreen(x, y)
    end

    if y == "center" then
        screenY = self.height / 2
    end

    -- Switch to text canvas for drawing
    love.graphics.setCanvas(self.textCanvas)
    -- transform coordinates to the textCanvas equivalent
    local tx = screenX / self.fontScale
    local ty = screenY / self.fontScale

    -- Apply the fade effect to the text color index
    local adjustedTextColorIndex = Transition:getAdjustedColorIndex(textColorIndex or 1)

    -- Set our pixel font
    love.graphics.setFont(self.pixelFont)

    -- Draw shadow if shadowColorIndex is provided
    if shadowColorIndex then
        local adjustedShadowColorIndex = Transition:getAdjustedColorIndex(shadowColorIndex)
        love.graphics.setColor(self.COLORS[adjustedShadowColorIndex])
        love.graphics.print(text, math.floor(tx) + 1, math.floor(ty) + 1)
    end

    -- Draw main text
    love.graphics.setColor(self.COLORS[adjustedTextColorIndex])
    love.graphics.print(text, math.floor(tx), math.floor(ty))

    -- Switch back to game canvas
    love.graphics.setCanvas(self.canvas)
end

return Renderer
